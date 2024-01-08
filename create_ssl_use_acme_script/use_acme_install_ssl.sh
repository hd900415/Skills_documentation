# acme.sh 申请证书
#  安装acme.sh
curl https://get.acme.sh | sh -s email=xakfcwom@gmail.com #email使用自己注册的email

# 设置默认申请证书方式
bash ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# 设置自动更新 # 实际是部署一个计划任务
50 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null

# 开始申请生成证书 #需要关闭nginx服务，等占用80端口的服务 
bash ~/.acme.sh/acme.sh --issue -d "admin.youlecheng.cc" --standalone -k ec-256 # 设置为自己的域名 admin.youlecheng.cc


bash ~/.acme.sh/acme.sh --issue --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please -d "*.youlecheng.online" --standalone -k ec-256

bash ~/.acme.sh/acme.sh --issue --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please -d "*.youlecheng.online" --standalone -k ec-256 --renew



# 目录认证
acme.sh --issue  -d kgjjfrj.cyou -d 5678utyf.cyou -d tydr634.cyou -d kyk237.cyou -d tydr634o.cyou -d uyo957.cyou -d rtyye27.cyou -d hkgtu.cyou -d vwwegwrb.cyou -d 1241455.cyou --webroot /data/web/bookdown.com/down1/

# 安装证书文件
bash ~/.acme.sh/acme.sh --install-cert -d "h5.5f8.top" --key-file /usr/local/openresty/nginx/conf/ssl/h5.5f8.top/privkey.key --fullchain-file /usr/local/openresty/nginx/conf/ssl/h5.5f8.top/fullchain.pem  --ecc




# 使用certbot 
yum install certbot -y

certbot certonly --standalone -d harbor.galaxymeeting.live