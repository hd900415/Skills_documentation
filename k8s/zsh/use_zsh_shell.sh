# yum install -y zsh 
# or apt -y install zsh 
# 最好使用源码安装
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

chsh -s /bin/zsh
echo $SHELL

# 安装插件(zsh-autosuggestions自动补全命令)和主题(agnoster)

# 官网    ： https://ohmyz.sh/
# github库： https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
# github文档：https://github.com/ohmyzsh/ohmyzsh/wiki

# 在/root/.zshrc 中更改对应的主题和插件名称
