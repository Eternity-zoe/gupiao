// 价格预警管理页面
import { StorageService } from '../service/StorageService';
import { StockService } from '../service/StockService';
import { PriceAlert, PriceAlertInput } from '../model/StockData';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
struct AlertManage {
  @State priceAlerts: PriceAlert[] = [];
  @State showAddDialog: boolean = false;
  @State newAlertStockGid: string = '';
  @State newAlertStockName: string = '';
  @State newAlertConditionType: 'above' | 'below' | 'range' = 'above';
  @State newAlertTargetPrice: string = '';
  @State newAlertMinPrice: string = '';
  @State newAlertMaxPrice: string = '';
  private checkTimer: number = -1;

  async aboutToAppear() {
    await this.loadAlerts();
    // 临时使用页面定时器检查预警（每2分钟）
    this.checkTimer = setInterval(() => {
      this.checkPriceAlerts();
    }, 120000);
  }

  aboutToDisappear() {
    if (this.checkTimer !== -1) {
      clearInterval(this.checkTimer);
    }
  }

  async checkPriceAlerts() {
    try {
      const activeAlerts = this.priceAlerts.filter(alert => alert.isActive);
      
      for (const alert of activeAlerts) {
        try {
          const stockInfo = await StockService.getStockData(alert.stockGid);
          if (!stockInfo) continue;
          
          const currentPrice = parseFloat(stockInfo.data.nowPri);
          let shouldNotify = false;
          let message = '';
          
          switch (alert.conditionType) {
            case 'above':
              if (alert.targetPrice && currentPrice >= alert.targetPrice) {
                shouldNotify = true;
                message = `${alert.stockName}(${alert.stockGid})价格已达到${alert.targetPrice}元，当前价格${currentPrice}元`;
              }
              break;
            case 'below':
              if (alert.targetPrice && currentPrice <= alert.targetPrice) {
                shouldNotify = true;
                message = `${alert.stockName}(${alert.stockGid})价格已低于${alert.targetPrice}元，当前价格${currentPrice}元`;
              }
              break;
            case 'range':
              if (alert.minPrice && alert.maxPrice && 
                  currentPrice >= alert.minPrice && currentPrice <= alert.maxPrice) {
                shouldNotify = true;
                message = `${alert.stockName}(${alert.stockGid})价格在区间${alert.minPrice}-${alert.maxPrice}元内，当前价格${currentPrice}元`;
              }
              break;
          }
          
          if (shouldNotify) {
            await this.sendNotification(alert, message);
            // 通知后禁用该预警
            const alerts = await StorageService.getPriceAlerts();
            const targetAlert = alerts.find(a => a.id === alert.id);
            if (targetAlert) {
              targetAlert.isActive = false;
              await StorageService.savePriceAlerts(alerts);
              await this.loadAlerts();
            }
          }
        } catch (error) {
          console.error('检查单个预警失败:', error);
        }
      }
    } catch (error) {
      console.error('检查价格预警失败:', error);
    }
  }

  async loadAlerts() {
    this.priceAlerts = await StorageService.getPriceAlerts();
  }


  async sendNotification(alert: PriceAlert, message: string) {
    try {
      // 创建点击跳转的WantAgent
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.example.gupiao',
            abilityName: 'EntryAbility',
            parameters: {
              router: 'pages/StockDetail',
              gid: alert.stockGid
            }
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0
      };
      
      const clickWantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      
      // 创建通知
      const notificationRequest: notificationManager.NotificationRequest = {
        id: Date.now(),
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '股票价格提醒',
            text: message
          }
        },
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        wantAgent: clickWantAgent
      };
      
      await notificationManager.publish(notificationRequest);
    } catch (error) {
      console.error('发送通知失败:', error);
    }
  }

  build() {
    Column() {
      // 标题栏
      this.buildHeader();
      
      if (this.priceAlerts.length === 0) {
        Column() {
          Text('暂无价格预警')
            .fontSize(14)
            .fontColor('#999999')
          
          Text('点击下方按钮添加预警')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.priceAlerts, (alert: PriceAlert) => {
            ListItem() {
              this.buildAlertItem(alert);
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .divider({
          strokeWidth: 1,
          color: '#F5F5F5'
        })
      }
      
      // 添加预警按钮
      Button('添加价格预警')
        .width('90%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#0A59F7')
        .margin({ top: 16, bottom: 16 })
        .onClick(() => {
          this.showAddDialog = true;
        })
    }
    .width('100%')
    .height('100%')
    .bindContentCover(this.showAddDialog, this.buildAddAlertDialog(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }

  @Builder
  buildHeader() {
    Row() {
      Image($r('app.media.layered_image'))
        .width(24)
        .height(24)
        .onClick(() => {
          router.back();
        })
      
      Text('价格预警')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildAlertItem(alert: PriceAlert) {
    Row() {
      Column() {
        Text(alert.stockName)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
        
        Text(alert.stockGid.toUpperCase())
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
        
        Text(this.getAlertConditionText(alert))
          .fontSize(13)
          .fontColor('#666666')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Column() {
        Toggle({ type: ToggleType.Switch, isOn: alert.isActive })
          .onChange(async (isOn: boolean) => {
            const alerts = await StorageService.getPriceAlerts();
            const targetAlert = alerts.find(a => a.id === alert.id);
            if (targetAlert) {
              targetAlert.isActive = isOn;
              await StorageService.savePriceAlerts(alerts);
              await this.loadAlerts();
            }
          })
        
        Text('删除')
          .fontSize(12)
          .fontColor('#E64545')
          .margin({ top: 12 })
          .onClick(async () => {
            try {
              await StorageService.deletePriceAlert(alert.id);
              await this.loadAlerts();
              
              promptAction.showToast({
                message: '预警已删除',
                duration: 2000
              });
            } catch (err) {
              console.error('删除预警失败:', err);
            }
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildAddAlertDialog() {
    Column() {
      Blank()
      
      Scroll() {
        Column() {
          Text('添加价格预警')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          
          // 股票代码
          TextInput({ placeholder: '股票代码（如：sh601009）' })
            .width('100%')
            .height(48)
            .fontSize(14)
            .margin({ top: 16 })
            .onChange((value: string) => {
              this.newAlertStockGid = value;
            })
          
          // 股票名称
          TextInput({ placeholder: '股票名称' })
            .width('100%')
            .height(48)
            .fontSize(14)
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.newAlertStockName = value;
            })
          
          // 条件类型
          Text('预警条件')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 16 })
            .alignSelf(ItemAlign.Start)
          
          Row() {
            this.buildConditionTypeButton('高于', 'above');
            this.buildConditionTypeButton('低于', 'below');
            this.buildConditionTypeButton('区间', 'range');
          }
          .width('100%')
          .margin({ top: 8 })
          
          // 价格输入
          if (this.newAlertConditionType === 'range') {
            Row() {
              TextInput({ placeholder: '最低价' })
                .layoutWeight(1)
                .height(48)
                .fontSize(14)
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.newAlertMinPrice = value;
                })
              
              Text('-')
                .fontSize(16)
                .fontColor('#666666')
                .margin({ left: 8, right: 8 })
              
              TextInput({ placeholder: '最高价' })
                .layoutWeight(1)
                .height(48)
                .fontSize(14)
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.newAlertMaxPrice = value;
                })
            }
            .width('100%')
            .margin({ top: 12 })
          } else {
            TextInput({ placeholder: '目标价格' })
              .width('100%')
              .height(48)
              .fontSize(14)
              .type(InputType.Number)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.newAlertTargetPrice = value;
              })
          }
          
          Row() {
            Button('取消')
              .fontSize(16)
              .fontColor('#666666')
              .backgroundColor('#F5F5F5')
              .layoutWeight(1)
              .height(48)
              .onClick(() => {
                this.resetAddDialog();
              })
            
            Button('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .backgroundColor('#0A59F7')
              .layoutWeight(1)
              .height(48)
              .margin({ left: 12 })
              .onClick(async () => {
                await this.addAlert();
              })
          }
          .width('100%')
          .margin({ top: 24 })
        }
        .width('90%')
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
      }
      .height('70%')
      
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }

  @Builder
  buildConditionTypeButton(label: string, type: 'above' | 'below' | 'range') {
    Text(label)
      .fontSize(14)
      .fontColor(this.newAlertConditionType === type ? '#FFFFFF' : '#666666')
      .backgroundColor(this.newAlertConditionType === type ? '#0A59F7' : '#F5F5F5')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .borderRadius(4)
      .margin({ right: 8 })
      .onClick(() => {
        this.newAlertConditionType = type;
      })
  }

  async addAlert() {
    try {
      if (!this.newAlertStockGid.trim() || !this.newAlertStockName.trim()) {
        promptAction.showToast({
          message: '请填写股票代码和名称'
        });
        return;
      }
      
      if (this.newAlertConditionType === 'range') {
        if (!this.newAlertMinPrice || !this.newAlertMaxPrice) {
          promptAction.showToast({
            message: '请填写价格区间'
          });
          return;
        }
        
        const rangeAlert: PriceAlertInput = {
          stockGid: this.newAlertStockGid.trim().toLowerCase(),
          stockName: this.newAlertStockName.trim(),
          conditionType: 'range',
          minPrice: parseFloat(this.newAlertMinPrice),
          maxPrice: parseFloat(this.newAlertMaxPrice),
          isActive: true
        };
        await StorageService.addPriceAlert(rangeAlert);
      } else {
        if (!this.newAlertTargetPrice) {
          promptAction.showToast({
            message: '请填写目标价格'
          });
          return;
        }
        
        const targetAlert: PriceAlertInput = {
          stockGid: this.newAlertStockGid.trim().toLowerCase(),
          stockName: this.newAlertStockName.trim(),
          conditionType: this.newAlertConditionType,
          targetPrice: parseFloat(this.newAlertTargetPrice),
          isActive: true
        };
        await StorageService.addPriceAlert(targetAlert);
      }
      
      await this.loadAlerts();
      this.resetAddDialog();
      
      promptAction.showToast({
        message: '预警添加成功'
      });
    } catch (err) {
      console.error('添加预警失败:', err);
    }
  }

  resetAddDialog() {
    this.showAddDialog = false;
    this.newAlertStockGid = '';
    this.newAlertStockName = '';
    this.newAlertConditionType = 'above';
    this.newAlertTargetPrice = '';
    this.newAlertMinPrice = '';
    this.newAlertMaxPrice = '';
  }

  getAlertConditionText(alert: PriceAlert): string {
    switch (alert.conditionType) {
      case 'above':
        return `价格高于 ${alert.targetPrice} 元`;
      case 'below':
        return `价格低于 ${alert.targetPrice} 元`;
      case 'range':
        return `价格在 ${alert.minPrice}-${alert.maxPrice} 元`;
      default:
        return '';
    }
  }
}
