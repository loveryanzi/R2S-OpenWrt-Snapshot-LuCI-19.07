#!/bin/bash
clear

MY_PATH=$(pwd)

# 调整再执行 02 脚本
## 删除 '翻译及部分功能优化'，为后续重写做准备
sed -i '/MY_Var/d' 02_prepare_package.sh
## 移除 fuck 组件
sed -i '/fuck/d' 02_prepare_package.sh
## 更换 LuCI 为 19.07 版本
sed -i 's/nicksun98\/openwrt/openwrt\/openwrt/' 02_prepare_package.sh
sed -i 's/^#\(patch -p1 < ..\/PATCH\/new\/main\/luci_network-add-packet-steering.patch\)/\1/' 02_prepare_package.sh
/bin/bash 02_prepare_package.sh

# 调整luci依赖，去除 luci-app-opkg，替换 luci-theme-bootstrap 为 luci-theme-argon
sed -i 's/+luci-app-opkg //' ./feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/' ./feeds/luci/collections/luci/Makefile

# 主题
rm -fr package/new/luci-theme-argon
git clone -b master --single-branch https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
sed -i '/<a class=\"luci-link\" href=\"https:\/\/github.com\/openwrt\/luci\">/d' package/new/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i '/<a href=\"https:\/\/github.com\/jerrykuku\/luci-theme-argon\">/d' package/new/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i '/<%= ver.distversion %>/d' package/new/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i '/<a href=\"https:\/\/github.com\/openwrt\/luci\">/d' feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/footer.htm

# SSRP 微调
pushd package/lean/
cp $MY_PATH/../PATCH/modifySSRPlus.sh ./
bash modifySSRPlus.sh
popd

# luci-app-clash
git clone https://github.com/frainzy1477/luci-app-clash.git package/luci-app-clash
pushd package/luci-app-clash
cp $MY_PATH/../PATCH/change-default-address-secret-for-clash-dashboard.patch ./
patch -p1 < 0001-change-default-address-secret-for-clash-dashboard.patch
popd

pushd package/luci-app-clash/tools/po2lmo
make && sudo make install
popd
po2lmo ./package/luci-app-clash/po/zh-cn/clash.po ./package/luci-app-clash/po/zh-cn/clash.zh-cn.lmo

#翻译及部分功能优化
MY_Var=package/lean/lean-translate
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh ${MY_Var}
sed -i '/uci .* dhcp/d' ${MY_Var}/files/zzz-default-settings
sed -i '/chinadnslist\|ddns\|upnp\|netease\|rng\|openclash\|dockerman/d' ${MY_Var}/files/zzz-default-settings
sed -i "4a uci set system.@system[0].hostname='NanoPi-R2S'" ${MY_Var}/files/zzz-default-settings
sed -i "5a uci commit system" ${MY_Var}/files/zzz-default-settings
sed -i "4a uci set dropbear.@dropbear[0].Interface='lan'" ${MY_Var}/files/zzz-default-settings
sed -i "5a uci commit dropbear" ${MY_Var}/files/zzz-default-settings
# sed -i "4a uci set clash.config.download_core='linux-armv8'" ${MY_Var}/files/zzz-default-settings
# sed -i "5a uci set clash.config.auto_update='0'" ${MY_Var}/files/zzz-default-settings
# sed -i "6a uci set clash.config.dcore='1'" ${MY_Var}/files/zzz-default-settings
# sed -i "7a uci commit clash" ${MY_Var}/files/zzz-default-settings
sed -i '/^[[:space:]]*$/d' ${MY_Var}/files/zzz-default-settings
unset MY_Var

# 移除 LuCI 部分页面
pushd feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d
rm -fr luci-mod-system.json
cp $MY_PATH/../PATCH/luci-mod-system.json ./
popd
pushd feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system
rm -fr flash.js mounts.js
popd
pushd feeds/luci/modules/luci-mod-system/luasrc/model/cbi/admin_system
rm -fr backupfiles.lua
popd

unset MY_PATH
exit 0
