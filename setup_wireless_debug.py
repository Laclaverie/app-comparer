import subprocess
import sys
import re
import time

def run_command(command, capture_output=True):
    """Run a command and return the result"""
    try:
        result = subprocess.run(command, shell=True, capture_output=capture_output, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def check_adb():
    """Check if ADB is available"""
    success, _, _ = run_command("adb version")
    return success

def get_connected_devices():
    """Get list of connected devices"""
    success, output, _ = run_command("adb devices")
    if success:
        lines = output.strip().split('\n')[1:]  # Skip header
        devices = [line.split('\t')[0] for line in lines if '\tdevice' in line]
        return devices
    return []

def get_device_ip():
    """Get device IP address"""
    success, output, _ = run_command("adb shell ip route | grep wlan")
    if success:
        # Extract IP from route output
        match = re.search(r'src (\d+\.\d+\.\d+\.\d+)', output)
        if match:
            return match.group(1)
    return None

def main():
    print("🚀 Setting up wireless debugging for Flutter app...")
    
    # Check ADB
    if not check_adb():
        print("❌ Error: ADB not found in PATH.")
        print("   Please install Android SDK Platform Tools.")
        return False
    
    # Check connected devices
    print("\n📱 Step 1: Checking connected devices...")
    devices = get_connected_devices()
    if not devices:
        print("❌ No devices connected via USB.")
        print("   Please connect your device and enable USB debugging.")
        return False
    
    print(f"✅ Found device(s): {', '.join(devices)}")
    
    # Enable TCP/IP mode
    print("\n🔧 Step 2: Enabling TCP/IP mode on port 5555...")
    success, _, error = run_command("adb tcpip 5555")
    if not success:
        print(f"❌ Failed to enable TCP/IP mode: {error}")
        return False
    print("✅ TCP/IP mode enabled")
    
    # Get device IP
    print("\n🌐 Step 3: Getting device IP address...")
    device_ip = get_device_ip()
    
    if not device_ip:
        print("⚠️  Could not automatically detect IP.")
        print("   Go to Settings > About Phone > Status > IP Address")
        device_ip = input("   Enter your device IP address: ")
    
    print(f"📍 Device IP: {device_ip}")
    
    # Wait for user to disconnect USB
    print("\n🔌 Step 4: You can now disconnect the USB cable.")
    input("   Press Enter when ready to continue...")
    
    # Connect via WiFi
    print("\n📶 Step 5: Connecting via WiFi...")
    time.sleep(2)  # Give some time after USB disconnect
    
    success, output, error = run_command(f"adb connect {device_ip}:5555")
    if "connected" in output.lower():
        print("✅ Connected successfully!")
    else:
        print(f"⚠️  Connection result: {output}")
    
    # Verify connection
    print("\n🔍 Step 6: Verifying connection...")
    devices = get_connected_devices()
    wireless_devices = [d for d in devices if ':5555' in d]
    
    if wireless_devices:
        print(f"✅ Wireless connection verified: {wireless_devices[0]}")
    else:
        print("❌ Wireless connection not found")
        return False
    
    # Success message
    print("\n🎉 Setup complete! You can now run your Flutter app wirelessly:")
    print("   melos run run:client")
    print("   or")
    print("   flutter run")
    print(f"\n💡 To reconnect later: adb connect {device_ip}:5555")
    print("💡 To disable wireless debugging: adb usb")
    
    return True

if __name__ == "__main__":
    success = main()
    if not success:
        input("\nPress Enter to exit...")
        sys.exit(1)