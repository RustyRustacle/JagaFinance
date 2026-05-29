# 1. Install JDK 17 or later from https://adoptium.net/
# 2. Edit variables below, then run this script from this directory

$KEYSTORE_DIR = "../keystore"
$KEYSTORE_FILE = "$KEYSTORE_DIR/jagafinance.jks"
$KEY_ALIAS = "jagafinance"
$KEY_VALIDITY = 10000

# Prompt for passwords
$storePass = Read-Host "Keystore password" -AsSecureString
$BSTR1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass)
$storePassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR1)

$keyPass = Read-Host "Key password (can match keystore)" -AsSecureString
$BSTR2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass)
$keyPassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR2)

# Generate keystore
if (-not (Test-Path $KEYSTORE_DIR)) { New-Item -ItemType Directory -Path $KEYSTORE_DIR }
& keytool -genkey -v -keystore $KEYSTORE_FILE -alias $KEY_ALIAS -keyalg RSA -keysize 2048 -validity $KEY_VALIDITY -storepass $storePassPlain -keypass $keyPassPlain -dname "CN=JagaFinance, OU=Engineering, O=JagaFinance, L=Jakarta, ST=Jakarta, C=ID"

Write-Host "Keystore created at $KEYSTORE_FILE"
Write-Host ""
Write-Host "Create key.properties from key.properties.example with the passwords above."
Write-Host "IMPORTANT: Add android/key.properties and android/keystore/ to .gitignore!"
