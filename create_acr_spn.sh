#!/bin/bash
#
# Run this script LOCALLY before any other script, run by typing ./serviceprincipal.sh
# To view the available roles, see https://docs.microsoft.com/azure/active-directory/role-based-access-built-in-roles Default recommended is Contributor, which can manage everything except access

# Read User Input to capture variables
    echo "This script will create a Service Principal (SPN) for Azure Container Registry."
    echo
    echo "Enter a name for your ACR SPN and press [ENTER]: "
    read name
    echo "The name you entered is $name."
    echo "Enter a password for your ACR SPN and press [ENTER]: "
    read -s password    
    echo 
    echo "Thank you for your input. Now proceeding with SPN creation..."

# Login - Complete this process using a browser
    if az account show &>/dev/null; then
            echo "You are already logged in to Azure..."
        else
            echo "Logging into Azure..."
                az login
                echo "Successfully logged into Azure..."
    fi

# Function for create_spn
create_spn () {
echo
echo "Creating your SPN for ACR now..."

# Capture id and login server
id=$(az acr list | jq -r '.[] | .id')
login_server=$(az acr list | jq -r '.[] | .loginServer')

# Begin AD Service Principal Creation for ACR

az ad sp create-for-rbac \
    -n $name \
    --scopes $id \
    --role Owner \
    --password $password \
    --verbose

# Capture new SPN appId in variable
appId=$(az ad sp show --id http://$name | jq -r '.appId') && echo "New ACR SPN appId captured successfully..."

# Output service principal
    echo "Successfully created ACR Service Principal..."
    echo 
    echo "ACR SPN Details:"
    echo "username=$appId"
    echo "password=$password"
    echo 

# Copy service principal to environment variables file
echo "Saving details to local env file in $(pwd)..."
echo "username=$appId
password=$password
" > acr.env
echo "acr.env created successfully..."
echo

# If previous SPN variables exist in ~/.bashrc, remove them but save .bak file
    sed -e "/spn/d;/password/d;/tenant/d" -i .bak ~/.bashrc
}

# Azure Subscription Selection
    # Check for multiple subscriptions
    echo "Checking Azure subscription count..."
    arrsize=$(az account list | jq '. | length')
    if [ "$arrsize" -eq "1" ]; then
        echo "You only have one subscription. Your SPN will be created in $(az account list | jq -r '.[] | .name')"
        create_spn 
        exit 0;
    # Multiple subscriptions found, begin selection option. 
    else 
        echo "Multiple subscriptions found!"
        echo "You have $arrsize available Azure subscriptions. Please select which subscription you would wish to create an SPN for:"
        echo 
    fi

    # Configure IFS (Internal Field Separator) to set a new line as word boundary. (Default whites space characters [space / tab / new line] for word boundary.)
        IFS=$'\n' 
    # Capture subscriptions in variable
        subscriptions=$(az account list | jq -r '.[] | .name')

    # Begin Subscription Menu
        echo "============================================="
        echo "          Azure Subscription Menu            "
        echo
        ### for-loop to display our subscription list, numbered.
        i=0;
        for subs in $subscriptions;
        do
        echo " $i) $subs"
        i=$((i+1));
        done
        echo 
        echo " e)  Exit This Tool                          "
        echo "============================================="
        echo
        menu_choice="";
    # While loop for menu selection
        shopt -s extglob #turn on extended pattern matching for +([0-9]) 
        while [ 1 ];
        do
            read -p "Please make a selection and press [ENTER]: " menu_choice

    # Menu selection 
            case $menu_choice in
                +([0-9])) 
                az account set --subscription $(az account list | jq -r --argjson v $menu_choice '.[$v] | .name')
                if [ $? -eq 0 ]
                    then
                        echo
                        echo "Successfully set your subscription to $(az account list | jq -r --argjson v $menu_choice '.[$v] | .name')"
                        create_spn
                        exit 0;
                else
                    echo "Could not set your subscription. Please check your entry and try again." >&2
                fi
                ;;

                e|E)
                    exit 0;
                    ;;
                *)
                    echo;echo;
                    echo "Invalid selection: $menu_choice"
                    echo;echo;
                    ;;
            esac
        done
        return 0;