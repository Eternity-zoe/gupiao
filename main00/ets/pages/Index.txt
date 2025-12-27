import { StockService } from '../service/StockService';
import { MarketPage } from './MarketPage';
import { FavoritePage } from './FavoritePage';
import { MinePage } from './MinePage';
import { StorageService } from '../service/StorageService';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0; // 默认显示行情页

  async aboutToAppear() {
    // 初始化存储服务
    const context = getContext(this) as common.UIAbilityContext;
    await StorageService.init(context);
  }

  build() {
    Column() {
      // 内容区域
      Stack() {
        // 行情页面 - 始终存在，通过visibility控制显示
        MarketPage()
          .visibility(this.currentTabIndex === 0 ? Visibility.Visible : Visibility.Hidden)
        
        // 自选页面 - 始终存在，通过visibility控制显示  
        FavoritePage()
          .visibility(this.currentTabIndex === 1 ? Visibility.Visible : Visibility.Hidden)
        
        // 我的页面 - 始终存在，通过visibility控制显示
        MinePage()
          .visibility(this.currentTabIndex === 2 ? Visibility.Visible : Visibility.Hidden)
      }
      .layoutWeight(1)
      
      // 底部TabBar
      this.buildTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTabBar() {
    Row() {
      this.buildTabItem(0, '行情', $r('app.media.layered_image'));
      this.buildTabItem(1, '自选', $r('app.media.layered_image'));
      this.buildTabItem(2, '我的', $r('app.media.layered_image'));
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .justifyContent(FlexAlign.SpaceAround)
    .border({
      width: { top: 1 },
      color: '#E5E5E5'
    })
  }

  @Builder
  buildTabItem(index: number, label: string, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentTabIndex === index ? '#0A59F7' : '#999999')
      
      Text(label)
        .fontSize(12)
        .fontColor(this.currentTabIndex === index ? '#0A59F7' : '#999999')
        .margin({ top: 4 })
    }
    .width('33.3%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTabIndex = index;
    })
  }
}
