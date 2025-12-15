import urllib.request
import json
import time
import threading
import random
import sys
from collections import deque

# Configuration
RPC_URL = "http://localhost:8565" # Mapped Geth port
THREADS = 10
REPORT_INTERVAL = 5

# Statistics
request_count = 0
error_count = 0
lock = threading.Lock()

def make_rpc_request(method, params=[]):
    """Helper to send JSON-RPC request"""
    global error_count
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1
    }
    
    try:
        req = urllib.request.Request(
            RPC_URL, 
            data=json.dumps(payload).encode('utf-8'), 
            headers={'Content-Type': 'application/json'}
        )
        with urllib.request.urlopen(req, timeout=3) as response:
            if response.status == 200:
                return json.loads(response.read().decode('utf-8')).get('result')
            else:
                with lock:
                    error_count += 1
                return None
    except Exception as e:
        with lock:
            error_count += 1
        return None

def worker():
    """Worker thread to generate load"""
    global request_count
    
    # Pre-fetch some blocks to seed data
    cached_blocks = deque(maxlen=20)
    
    while True:
        try:
            # MIX OF OPERATIONS
            op = random.random()
            
            if op < 0.3:
                # 30% fetches latest block
                block = make_rpc_request("eth_getBlockByNumber", ["latest", True])
                if block:
                    cached_blocks.append(block)
            
            elif op < 0.6 and len(cached_blocks) > 0:
                # 30% re-fetches a recent block (mimics users checking confirmations)
                block = random.choice(cached_blocks)
                if block:
                    make_rpc_request("eth_getBlockByNumber", [block['number'], False])
            
            elif op < 0.9 and len(cached_blocks) > 0:
                 # 30% fetches transactions or balances from data seen in blocks
                block = random.choice(cached_blocks)
                txs = block.get('transactions', [])
                if txs:
                    tx = random.choice(txs)
                    # Fetch TX details
                    make_rpc_request("eth_getTransactionByHash", [tx['hash']])
                    # Fetch Sender Balance
                    make_rpc_request("eth_getBalance", [tx['from'], "latest"])
            
            else:
                # 10% random noise / basic info
                make_rpc_request("eth_blockNumber")
                make_rpc_request("net_version")

            with lock:
                request_count += 1
                
            # Slight sleep to prevent absolute CPU locking of the script itself
            # time.sleep(0.01) 

        except Exception as e:
            pass

def reporter():
    """Thread to print statistics"""
    global request_count, error_count
    last_count = 0
    while True:
        time.sleep(REPORT_INTERVAL)
        with lock:
            current = request_count
            errors = error_count
            
        diff = current - last_count
        rps = diff / REPORT_INTERVAL
        
        print(f"[{time.strftime('%H:%M:%S')}] RPS: {rps:.1f} | Total: {current} | Errors: {errors}")
        last_count = current

def main():
    print(f"Starting Load Generator on {RPC_URL} with {THREADS} threads...")
    print("Press Ctrl+C to stop.")
    
    # Start Worker Threads
    threads = []
    for i in range(THREADS):
        t = threading.Thread(target=worker, daemon=True)
        t.start()
        threads.append(t)
        
    # Start Reporter
    t_report = threading.Thread(target=reporter, daemon=True)
    t_report.start()
    
    # Keep main alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nStopping...")

if __name__ == "__main__":
    main()
