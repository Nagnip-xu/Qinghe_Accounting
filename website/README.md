# 青禾记账官方网站

这是青禾记账应用的官方网站项目，采用HTML、CSS和JavaScript构建的现代化响应式网站。

## 网站结构

```
website/
├── index.html          # 主页HTML
├── css/                # 样式文件目录
│   └── styles.css      # 主样式文件
├── js/                 # JavaScript文件目录
│   └── main.js         # 主脚本文件
├── images/             # 图片资源目录
│   ├── logo.png        # 网站logo
│   ├── hero-device.png # 首屏展示图
│   ├── screenshot-*.jpg # 应用截图
│   └── *-qr.png        # 下载二维码
└── fonts/              # 字体文件目录（如需自定义字体）
```

## 功能特点

- 响应式设计，适配各种设备屏幕
- 现代化UI/UX，符合当代网页设计美学
- 平滑滚动和动画效果
- 图片轮播展示
- 手风琴式FAQ展示
- 移动设备友好的导航菜单

## 内容模块

网站包含以下主要内容模块：

1. **首屏介绍** - 简明扼要地展示应用的核心价值
2. **功能特点** - 详细介绍应用的主要功能
3. **应用截图** - 展示应用界面和用户体验
4. **下载链接** - 提供应用下载方式
5. **常见问题** - 解答用户可能遇到的问题
6. **页脚信息** - 提供联系方式和其他必要信息

## 使用说明

1. 将整个`website`目录部署到Web服务器上
2. 确保所有资源文件（图片、CSS、JS）都已正确上传
3. 访问网站首页（index.html）查看效果

## 自定义与维护

### 更新应用截图
替换`images`目录下的screenshot-*.jpg文件，保持文件名不变

### 更新下载链接
在index.html文件中查找下载按钮部分，更新href属性为新的应用下载链接

### 更新内容
直接编辑index.html文件中相应的文本内容

## 注意事项

- 网站使用了Font Awesome图标库，需要保持CDN链接可用
- 网站使用了响应式设计，建议定期在不同设备上测试显示效果
- 为获得最佳性能，建议优化所有图片资源

# 青禾记账网站展示优化指南

## 问题描述
当前网站上的应用截图展示不完整，部分界面被截断，无法完整展示应用的功能和设计。

## 解决方案
需要修改网站代码，优化截图展示方式，确保界面完整可见。

### 修改步骤

1. **调整截图容器尺寸**

   在 `css/styles.css` 文件中找到 `.screenshot` 相关样式，增加容器高度并调整图片展示方式：

   ```css
   .screenshot {
     height: auto; /* 改为自适应高度 */
     max-height: 600px; /* 设置最大高度 */
     overflow: visible; /* 改为可见溢出内容 */
   }
   
   .screenshot img {
     width: 100%;
     height: auto;
     object-fit: contain; /* 确保图片完整显示 */
     max-height: 580px; /* 设置图片最大高度 */
   }
   ```

2. **优化轮播展示逻辑**

   修改 `js/main.js` 中的轮播逻辑，确保图片完整展示：

   ```javascript
   // 在轮播初始化时添加以下配置
   const screenshotSlider = new Swiper('.screenshot-slider', {
     // 其他配置...
     autoHeight: true, // 启用自动高度
     watchOverflow: true, // 监视溢出
     updateOnImagesReady: true, // 图片加载完成后更新
   });
   ```

3. **响应式布局调整**

   为确保在不同设备上都能完整展示界面，添加以下媒体查询：

   ```css
   @media (max-width: 768px) {
     .screenshot {
       max-height: 450px;
     }
     
     .screenshot img {
       max-height: 430px;
     }
   }
   
   @media (max-width: 480px) {
     .screenshot {
       max-height: 350px;
     }
     
     .screenshot img {
       max-height: 330px;
     }
   }
   ```

4. **图片预处理**

   为确保图片质量和加载速度的平衡，建议对截图进行以下处理：
   
   - 统一调整尺寸为 1080×1920 像素
   - 使用适当的压缩算法减小文件大小（目标每张不超过 300KB）
   - 保持清晰度的同时优化文件大小

## 测试验证

完成上述修改后，请在以下环境中测试网站展示效果：

1. 桌面浏览器（Chrome、Firefox、Safari、Edge）
2. 平板设备（横屏和竖屏模式）
3. 移动设备（不同尺寸的手机）

确保在所有设备上，应用截图都能完整展示，无截断现象。

## 其他建议

- 考虑添加图片点击放大功能，让用户可以查看更大更清晰的截图
- 优化图片加载方式，使用延迟加载技术提高页面加载速度
- 为截图添加简短的功能说明，帮助用户更好理解应用功能 