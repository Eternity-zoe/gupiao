// 我的页面
import router from '@ohos.router';

@Component
export struct MinePage {
  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      Scroll() {
        Column() {
          // 功能列表
          this.buildMenuItem('价格预警', '设置股票价格提醒', 'pages/AlertManage');
          this.buildMenuItem('分组管理', '管理自选股分组', 'pages/GroupManage');
          
          // 关于信息
          Column() {
            Text('鸿股通')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .margin({ bottom: 8 })
            
            Text('股票实时查询工具')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 4 })
            
            Text('数据来源：聚合数据')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 4 })
            
            Text('仅供学习参考，不作投资建议')
              .fontSize(12)
              .fontColor('#FF6B6B')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 16 })
          .alignItems(HorizontalAlign.Start)
        }
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMenuItem(title: string, subtitle: string, url: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
        
        Text(subtitle)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Image($r('app.media.layered_image'))
        .width(16)
        .height(16)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      router.pushUrl({ url: url }, router.RouterMode.Standard);
    })
  }
}
