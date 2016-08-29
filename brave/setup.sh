[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }

# Pro Tip for ad-hoc building: add your app id as an arg, like ./setup.sh org.foo.myapp

app_id=${1:-com.brave.ios.browser}
echo CUSTOM_BUNDLE_ID=$app_id > xcconfig/.bundle-id.xcconfig
# Custom IDs get the BETA property set automatically
[[  -z $1 ]] || echo BETA=Beta >> xcconfig/.bundle-id.xcconfig

# if a brave build, setup fabric
if [ $app_id = com.brave.ios* ]; then
  echo "./Fabric.framework/run $(head -1 ~/.brave-fabric-keys) $(tail -1 ~/.brave-fabric-keys)" > build-system/.fabric-key-setup.sh
else
   >build-system/.fabric-key-setup.sh
fi

sed -e "s/BUNDLE_ID_PLACEHOLDER/$app_id/" Brave.entitlements.template > Brave.entitlements

npm update

echo GENERATED_BUILD_ID=`date +"%y.%m.%d.%H"`  > xcconfig/build-id.xcconfig

printf 'Please use our commit template, run this to install it\n\n git config commit.template brave/COMMIT_TEMPLATE\n\n'
