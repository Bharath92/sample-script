echo "Extracting aws creds"
node GET/sample-script/sample-script/extractAWSCreds.js $(cat GET/env-aws/aws.json) >  aws.tfvars

echo "Copying previous state file"
cp previousOutput/terraform.tfstate GET/sample-script/sample-script
 
echo "Fetching terraform"
wget https://releases.hashicorp.com/terraform/0.6.16/terraform_0.6.16_linux_386.zip
apt-get install unzip
unzip terraform_0.6.16_linux_386.zip

./terraform apply -var-file=aws.tfvars GET/sample-script/sample-script

echo "Copy state output to output directory"
cp GET/sample-script/sample-script/terraform.tfstate output/

