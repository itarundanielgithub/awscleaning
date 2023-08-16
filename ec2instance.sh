#!/bin/bash

cat <<EOL > user.data
#!/bin/bash
sudo hostname awslinux01
sudo echo awslinux01 > /etc/hostname
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config
echo 'password123' | passwd --stdin root
systemctl restart sshd
#yum install pip -y
#pip install aws-shell --ignore-installed configobj
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd
EOL

ami="ami-0ccb473bada910e74"
subnet=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)

securitygroupid=$(aws ec2 create-security-group --group-name arunhome3 --description "arunHome3" --query 'GroupId' --output text)

cidr_blocks=()

while true; do
    echo -n "Enter a CIDR block (or 'exit' to stop): "
    read cidr

    if [ "$cidr" == "exit" ]; then
        break
    fi

    cidr_blocks+=("$cidr")
done

for block in "${cidr_blocks[@]}"; do
    command="aws ec2 authorize-security-group-ingress --group-id $securitygroupid --protocol -1 --port -1 --cidr $block/32"
    echo "Executing: $command"
    $command
done

ec2=$(aws ec2 run-instances --image-id $ami --instance-type t2.micro --count 1 --security-group-ids $securitygroupid --subnet-id $subnet --user-data file://user.data --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids $ec2

aws ec2 describe-instances --instance-ids $ec2 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

