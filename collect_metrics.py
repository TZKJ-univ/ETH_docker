import urllib.request
import urllib.error
import json
import subprocess
import time
import csv
import re
import datetime
import os

# Configuration
GETH_METRICS_URL = "http://localhost:6060/debug/metrics/prometheus"
PRYSM_METRICS_URL = "http://localhost:5054/metrics" # Mapped from 8080 in docker-compose
GETH_RPC_URL = "http://localhost:8565"
PRYSM_API_URL = "http://localhost:5052/eth/v1/node/health" # Mapped from 5052
INTERVAL = 10  # Seconds

def measure_latency(url):
    """Measure HTTP round-trip time in milliseconds."""
    start = time.time()
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            response.read()
        return (time.time() - start) * 1000
    except Exception as e:
        # print(f"Error measuring latency for {url}: {e}")
        return 0

def fetch_prometheus_metric(url, metric_name, labels={}):
    """Simple parser to find a metric value from Prometheus text format."""
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = response.read().decode('utf-8')
            
            # Construct label string, e.g. {key="val",key2="val2"}
            label_str = ""
            if labels:
                parts = [f'{k}="{v}"' for k, v in labels.items()]
                label_str = r"\{" + r",".join(parts) + r"\}"
            
            # Regex to find the metric line
            if label_str:
                 pattern = re.compile(rf"^{re.escape(metric_name)}{label_str}\s+([\d\.]+)", re.MULTILINE)
            else:
                 pattern = re.compile(rf"^{re.escape(metric_name)}(?:\{{[^}}]*\}})?\s+([\d\.]+)", re.MULTILINE)

            match = pattern.search(data)
            if match:
                return float(match.group(1))
    except Exception as e:
        # print(f"Error fetching metric {metric_name} from {url}: {e}")
        pass
    return 0

def get_json_rpc(url, method, params=[]):
    """Make a JSON-RPC call."""
    try:
        data = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": 1
        }
        req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=5) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result.get('result')
    except Exception as e:
        # print(f"RPC Error {method}: {e}")
        return None

def main():
    # Generate filename with timestamp
    output_dir = "csv"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    start_time = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file = os.path.join(output_dir, f"node_metrics_{start_time}.csv")
    
    print(f"Starting metrics collection. Saving to {csv_file}...")
    print("Press Ctrl+C to stop.")

    # Initialize CSV
    headers = [
        "Timestamp",
        "Geth_Latency(ms)", "Geth_Peers", "Geth_Block", "Geth_TX_Pending",
        "Geth_GasPrice(Gwei)", "Geth_BaseFee(Gwei)", "Geth_GasUsed", "Geth_GasLimit", "Geth_GasUsage(%)", "Geth_TxCount", "Geth_Internal_Latency(us)",
        "Prysm_Latency(ms)", "Prysm_Peers", "Prysm_Slot", "Prysm_Finalized", "Prysm_Validators", "Prysm_Reorgs"
    ]
    
    with open(csv_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)

    try:
        while True:
            timestamp = datetime.datetime.now().isoformat()
            
            # 1. Latency (Ping)
            geth_latency = measure_latency(GETH_METRICS_URL) 
            prysm_latency = measure_latency(PRYSM_API_URL)

            # 2. Internal Metrics
            # Geth Prom
            geth_peers = fetch_prometheus_metric(GETH_METRICS_URL, "p2p_peers")
            geth_block = fetch_prometheus_metric(GETH_METRICS_URL, "chain_head_block")
            geth_tx_pending = fetch_prometheus_metric(GETH_METRICS_URL, "txpool_pending")
            
            # Geth Internal Latency (RPC duration 95%ile)
            geth_internal_latency = fetch_prometheus_metric(GETH_METRICS_URL, "rpc_duration_all", {"quantile": "0.95"})
            
            # Geth RPC (Gas & Throughput)
            gas_price_wei = get_json_rpc(GETH_RPC_URL, "eth_gasPrice")
            gas_price_gwei = int(gas_price_wei, 16) / 1e9 if gas_price_wei else 0
            
            latest_block = get_json_rpc(GETH_RPC_URL, "eth_getBlockByNumber", ["latest", False])
            
            base_fee_gwei = 0
            gas_used = 0
            gas_limit = 0
            gas_usage_percent = 0
            tx_count = 0
            
            if latest_block:
                base_fee_wei = latest_block.get('baseFeePerGas')
                if base_fee_wei:
                    base_fee_gwei = int(base_fee_wei, 16) / 1e9
                
                gas_used = int(latest_block.get('gasUsed', '0'), 16)
                gas_limit = int(latest_block.get('gasLimit', '0'), 16)
                if gas_limit > 0:
                    gas_usage_percent = (gas_used / gas_limit) * 100
                
                # Count transactions (Throughput)
                transactions = latest_block.get('transactions', [])
                tx_count = len(transactions)

            # Prysm Prom
            prysm_peers = fetch_prometheus_metric(PRYSM_METRICS_URL, "p2p_peer_count")
            prysm_slot = fetch_prometheus_metric(PRYSM_METRICS_URL, "beacon_head_slot")
            prysm_finalized = fetch_prometheus_metric(PRYSM_METRICS_URL, "beacon_finalized_epoch")
            prysm_validators = fetch_prometheus_metric(PRYSM_METRICS_URL, "beacon_current_active_validators")
            prysm_reorgs = fetch_prometheus_metric(PRYSM_METRICS_URL, "beacon_reorgs_total")

            row = [
                timestamp,
                f"{geth_latency:.2f}", int(geth_peers), int(geth_block), int(geth_tx_pending),
                f"{gas_price_gwei:.2f}", f"{base_fee_gwei:.2f}", int(gas_used), int(gas_limit), f"{gas_usage_percent:.2f}", int(tx_count), f"{geth_internal_latency:.2f}",
                f"{prysm_latency:.2f}", int(prysm_peers), int(prysm_slot), int(prysm_finalized), int(prysm_validators), int(prysm_reorgs)
            ]

            print(f"Collected: {row}")

            with open(csv_file, 'a', newline='') as f:
                writer = csv.writer(f)
                writer.writerow(row)

            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print("\nStopping collection.")

if __name__ == "__main__":
    main()
