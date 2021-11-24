echo "Installing terraform for Ubuntu"
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
echo "Checking installation has been succeded:"
terraform help
echo "install ansible for Ubuntu"
sudo apt update -y
sudo apt install ansible -y
echo "Ansible installation has been succeded"
echo "Echo installing AWS CLI"
sudo apt update -y
sudo apt install awscli
echo "AWS CLI installation is succeded"
echo "The next step is setup your connection using the command aws configure"
echo "You need to provide Access_Key_id, Secret_access_key and prefered region"
echo "Prereq is completed"
exit

