import json
import urllib.request

# Đọc token
with open('response.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
    token = data['data']['token']

url = 'http://localhost:8081/api/admin/students/2001215001/reset-password'
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {token}'
}
data = json.dumps({'newPassword': 'mypassword123'}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        result = response.read().decode('utf-8')
        print('Reset success:', result)
except Exception as e:
    print('Error:', e)
