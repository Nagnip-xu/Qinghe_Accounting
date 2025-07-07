# 青禾记账官网安装指南

## 前提条件

部署青禾记账官网需要具备以下条件：
- Web服务器（Apache、Nginx等）
- 基本的FTP/SFTP访问权限
- 域名（可选）

## 安装步骤

### 1. 准备图片资源

在部署网站前，请确保`images`目录下包含以下必要图片：
- logo.png
- hero-device.png
- screenshot-1.jpg 至 screenshot-5.jpg
- android-qr.png 和 ios-qr.png

您可以根据`images/placeholder.txt`文件中的说明准备这些图片。

### 2. 部署到Web服务器

#### 使用FTP/SFTP
1. 使用FTP客户端（如FileZilla）连接到您的Web服务器
2. 在服务器上创建一个目录（例如`qinghe-website`）
3. 上传整个`website`目录的内容到此目录
4. 确保所有文件的权限正确（通常是755对目录，644对文件）

#### 使用cPanel/宝塔面板
1. 登录到您的控制面板
2. 找到文件管理器选项
3. 导航到您想要部署网站的公共目录
4. 上传所有文件（可能需要先压缩文件以加快上传速度）

### 3. 配置Web服务器

#### Apache配置
确保您的`.htaccess`文件包含以下内容以启用gzip压缩和缓存：

```apache
# 启用压缩
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript
</IfModule>

# 启用缓存
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
  ExpiresByType text/html "access plus 1 day"
</IfModule>
```

#### Nginx配置
如果使用Nginx，确保您的服务器配置包含以下设置：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/qinghe-website;
    index index.html;

    # 启用gzip压缩
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml;

    # 设置缓存
    location ~* \.(jpg|jpeg|png|gif|ico)$ {
        expires 1y;
        add_header Cache-Control "public";
    }

    location ~* \.(css|js)$ {
        expires 1M;
        add_header Cache-Control "public";
    }
}
```

### 4. 验证安装

1. 在浏览器中访问您的网站
2. 检查所有页面和图片是否正确显示
3. 测试响应式布局（在不同尺寸设备上查看）
4. 验证所有链接和按钮是否正常工作

## 故障排除

### 图片无法显示
- 检查图片文件是否已上传到正确的位置
- 验证文件名和HTML中引用的名称是否匹配
- 检查文件权限是否正确

### 样式或脚本不加载
- 检查网络请求，查看是否有404错误
- 验证文件路径是否正确
- 检查文件权限

### 网站加载缓慢
- 优化图片大小
- 启用服务器压缩
- 配置适当的缓存头

## 联系支持

如有任何安装问题，请联系：support@qinghe.app 