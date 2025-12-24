// 股票卡片页面布局
@Entry(LocalStorage.getShared())
@Component
struct StockWidgetCard {
  @LocalStorageProp('title') title: string = '股票行情';
  @LocalStorageProp('updateTime') updateTime: string = '';
  @LocalStorageProp('shIndex') shIndex: string = '--';
  @LocalStorageProp('shChange') shChange: string = '--';
  @LocalStorageProp('shChangeColor') shChangeColor: string = '#999999';
  @LocalStorageProp('szIndex') szIndex: string = '--';
  @LocalStorageProp('szChange') szChange: string = '--';
  @LocalStorageProp('szChangeColor') szChangeColor: string = '#999999';
  @LocalStorageProp('isLoading') isLoading: boolean = false;

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        
        Text(this.updateTime)
          .fontSize(10)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8 })
      
      if (this.isLoading) {
        // 加载状态
        Column() {
          Text('加载中...')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 指数数据
        Column() {
          // 上证指数
          Row() {
            Column() {
              Text('上证指数')
                .fontSize(10)
                .fontColor('#666666')
              
              Text(this.shIndex)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            Text(this.shChange)
              .fontSize(12)
              .fontColor(this.shChangeColor)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.shChangeColor === '#E64545' ? '#FFEBEE' : 
                              this.shChangeColor === '#00B578' ? '#E8F5E9' : '#F5F5F5')
              .borderRadius(4)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })
          
          // 深证成指
          Row() {
            Column() {
              Text('深证成指')
                .fontSize(10)
                .fontColor('#666666')
              
              Text(this.szIndex)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A1A')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            Text(this.szChange)
              .fontSize(12)
              .fontColor(this.szChangeColor)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.szChangeColor === '#E64545' ? '#FFEBEE' : 
                              this.szChangeColor === '#00B578' ? '#E8F5E9' : '#F5F5F5')
              .borderRadius(4)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8 })
          
          // 操作按钮
          Row() {
            Text('刷新')
              .fontSize(10)
              .fontColor('#0A59F7')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(4)
              .border({ width: 1, color: '#0A59F7' })
              .onClick(() => {
                postCardAction(this, {
                  action: 'message',
                  params: {
                    message: 'refresh'
                  }
                });
              })
            
            Blank()
            
            Text('打开应用')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor('#0A59F7')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(4)
              .onClick(() => {
                postCardAction(this, {
                  action: 'router',
                  abilityName: 'EntryAbility',
                  params: {
                    router: 'pages/Index'
                  }
                });
              })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .padding(4)
  }
}
