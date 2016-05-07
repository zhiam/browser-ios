## Anyone with access to the dev@brave.com account can use this to grab the dev and dist profiles

which -s sigh
if [[ $? != 0 ]] ; then
  gem install fastlane --no-doc --no-ri --user-install -n/usr/local/bin
fi

rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

[[ -e ~/.brave-apple-login ]] && source ~/.brave-apple-login

sigh download_all -u dev@brave.com -a com.brave.ios.browser
sigh manage -p "XC.*" --force # remove XCode managed profiles

[[ $1 == "beta" ]] &&  sigh manage -p "dist*" --force 
[[ $1 == "release" ]] &&  sigh manage -p "beta_*" --force

rm -f *.mobileprovision
