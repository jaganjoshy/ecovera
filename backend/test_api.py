import requests
import json
import time
import sys

class APITester:
    def __init__(self, base_url="http://192.168.148.84:5000"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def check_server_health(self):
        """Check if the server is running and healthy"""
        try:
            response = self.session.get(f"{self.base_url}/health")
            if response.status_code == 200:
                print("✓ Server is healthy")
                return True
            else:
                print(f"✗ Server health check failed: {response.json().get('message', 'Unknown error')}")
                return False
        except requests.exceptions.ConnectionError:
            print("✗ Could not connect to server. Is it running?")
            return False
    
    def test_predict(self, data=None):
        """Test the predict endpoint"""
        if data is None:
            data = {
                "N": 90.0,
                "P": 42.0,
                "K": 43.0,
                "temperature": 20.87,
                "humidity": 82.00,
                "ph": 6.50,
                "rainfall": 202.93,
                "moisture": 50.0
            }
        
        try:
            print("\nTesting /predict endpoint...")
            response = self.session.post(f"{self.base_url}/predict", json=data)
            print(f"Status Code: {response.status_code}")
            print("Response:")
            print(json.dumps(response.json(), indent=2))
            return response.status_code == 200
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")
            return False
    
    def test_invalid_input(self):
        """Test the predict endpoint with invalid input"""
        print("\nTesting invalid input...")
        invalid_data = {
            "N": "invalid",
            "P": 42.0,
            "K": 43.0,
            "temperature": 20.87,
            "humidity": 82.00,
            "ph": 6.50,
            "rainfall": 202.93,
            "moisture": 50.0
        }
        try:
            response = self.session.post(f"{self.base_url}/predict", json=invalid_data)
            print(f"Status Code: {response.status_code}")
            print("Response:")
            print(json.dumps(response.json(), indent=2))
            return response.status_code == 400
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")
            return False

def main():
    tester = APITester()
    
    # Wait for server to start
    max_retries = 5
    for i in range(max_retries):
        if tester.check_server_health():
            break
        if i < max_retries - 1:
            print(f"Retrying in 2 seconds... ({i + 1}/{max_retries})")
            time.sleep(2)
        else:
            print("Server not responding after maximum retries")
            sys.exit(1)
    
    # Run tests
    tests_passed = 0
    total_tests = 2
    
    if tester.test_predict():
        tests_passed += 1
    
    if tester.test_invalid_input():
        tests_passed += 1
    
    print(f"\nTests completed: {tests_passed}/{total_tests} passed")
    sys.exit(0 if tests_passed == total_tests else 1)

if __name__ == "__main__":
    main() 