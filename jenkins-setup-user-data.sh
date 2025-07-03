#!/bin/bash

# Update Package Repository and Upgrade Packages
apt update
apt upgrade -y

# Create Jenkins User with password
useradd -m -s /bin/bash jenkins
echo "jenkins:jenkins" | chpasswd

# Grant Sudo Rights to Jenkins User
usermod -aG sudo jenkins

# Add Adoptium repository
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list

# Install Java 11
apt update
apt install -y temurin-11-jdk

# Install Docker prerequisites
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    netcat

# Add Docker's official GPG key
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create docker group and add jenkins user
groupadd docker || true
usermod -aG docker jenkins

# Get the instance's public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create verification script
cat << EOF > /home/jenkins/verify_installation.sh
#!/bin/bash

echo "=== Verification Script ==="
echo

echo "1. Checking Jenkins user:"
id jenkins
echo

echo "2. Checking sudo access:"
sudo -l -U jenkins
echo

echo "3. Checking Java installation:"
java -version
echo

echo "4. Checking Docker installation:"
docker --version
echo

echo "5. Checking Docker group membership:"
groups jenkins
echo

echo "6. Testing Docker access:"
docker run hello-world
echo

echo "7. Checking required ports:"
echo "Checking port 8080 (Jenkins):"
nc -zv localhost 8080 2>&1 || echo "Port 8080 is not open"
echo "Checking port 9000 (SonarQube):"
nc -zv localhost 9000 2>&1 || echo "Port 9000 is not open"
echo

echo "8. Webhook Configuration Information:"
echo "SonarQube Webhook URL: http://${PUBLIC_IP}:8080/sonarqube-webhook/"
echo

echo "=== Verification Complete ==="
EOF

# Set permissions for verification script
chown jenkins:jenkins /home/jenkins/verify_installation.sh
chmod +x /home/jenkins/verify_installation.sh

# Create a README file with instructions
cat << EOF > /home/jenkins/README.txt
Jenkins Server Setup Instructions
===============================

1. SSH into the server as jenkins user:
   ssh jenkins@<server-ip>
   Password: jenkins

2. Run the verification script:
   ./verify_installation.sh

3. Expected results:
   - Jenkins user should exist and have sudo access
   - Java 11 should be installed
   - Docker should be installed and accessible
   - Docker hello-world container should run successfully

4. Required Ports for Webhook Communication:
   - Port 8080: Jenkins web interface
   - Port 9000: SonarQube web interface
   Make sure these ports are open in your EC2 security group.

5. SonarQube Webhook Configuration:
   - Go to SonarQube web interface (http://${PUBLIC_IP}:9000)
   - Navigate to Administration → Configuration → Webhooks
   - Add a new webhook
   - Set the URL to: http://${PUBLIC_IP}:8080/sonarqube-webhook/
   - Save the webhook

6. If any checks fail:
   - Check the error messages
   - Verify the user data script execution in the system log
   - Contact system administrator if issues persist

Note: You may need to run 'newgrp docker' after first login to activate Docker group membership.
EOF

chown jenkins:jenkins /home/jenkins/README.txt

# Print initial access information
echo "==============================================="
echo "Jenkins server has been set up!"
echo "==============================================="
echo "SSH into the server as jenkins user:"
echo "ssh jenkins@${PUBLIC_IP}"
echo "Password: jenkins"
echo "==============================================="
echo "After logging in, run ./verify_installation.sh"
echo "to verify all components are working correctly."
echo "==============================================="
echo "Required ports for webhook communication:"
echo "- Port 8080: Jenkins web interface"
echo "- Port 9000: SonarQube web interface"
echo "==============================================="
echo "SonarQube Webhook URL:"
echo "http://${PUBLIC_IP}:8080/sonarqube-webhook/"
echo "==============================================="

# Reboot the system to apply all changes
reboot 