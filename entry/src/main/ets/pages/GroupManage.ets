// 分组管理页面
import { StorageService } from '../service/StorageService';
import { StockGroup } from '../model/StockData';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct GroupManage {
  @State stockGroups: StockGroup[] = [];
  @State showAddDialog: boolean = false;
  @State showAddStockDialog: boolean = false;
  @State newGroupName: string = '';
  @State newStockGid: string = '';
  @State selectedGroupId: string = '';

  async aboutToAppear() {
    await this.loadGroups();
  }

  async loadGroups() {
    this.stockGroups = await StorageService.getStockGroups();
  }

  build() {
    Column() {
      // 标题栏
      this.buildHeader();
      
      // 分组列表
      List() {
        ForEach(this.stockGroups, (group: StockGroup) => {
          ListItem() {
            this.buildGroupItem(group);
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .divider({
        strokeWidth: 8,
        color: '#F5F5F5'
      })
      
      // 添加分组按钮
      Button('新建分组')
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
    .bindContentCover(this.showAddDialog, this.buildAddGroupDialog(), {
      modalTransition: ModalTransition.DEFAULT
    })
    .bindContentCover(this.showAddStockDialog, this.buildAddStockDialog(), {
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
      
      Text('分组管理')
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
  buildGroupItem(group: StockGroup) {
    Column() {
      Row() {
        Column() {
          Text(group.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
          
          Text(`${group.stocks.length}只股票`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Row() {
          Button('添加股票')
            .fontSize(14)
            .fontColor('#0A59F7')
            .backgroundColor('transparent')
            .height(32)
            .onClick(() => {
              this.selectedGroupId = group.id;
              this.showAddStockDialog = true;
            })
          
          if (group.id !== 'default') {
            Button('删除')
              .fontSize(14)
              .fontColor('#E64545')
              .backgroundColor('transparent')
              .height(32)
              .margin({ left: 8 })
              .onClick(() => {
                this.deleteGroup(group.id, group.name);
              })
          }
        }
      }
      .width('100%')
      .padding(16)
      
      // 股票列表
      if (group.stocks.length > 0) {
        Column() {
          ForEach(group.stocks, (gid: string) => {
            Row() {
              Text(gid.toUpperCase())
                .fontSize(14)
                .fontColor('#1A1A1A')
                .layoutWeight(1)
              
              Text('移除')
                .fontSize(12)
                .fontColor('#E64545')
                .onClick(() => {
                  this.removeStock(group.id, gid);
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#F8F8F8')
            .margin({ top: 4 })
            .borderRadius(4)
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildAddGroupDialog() {
    Column() {
      Blank()
      
      Column() {
        Text('新建分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        
        TextInput({ placeholder: '请输入分组名称' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .margin({ top: 24 })
          .onChange((value: string) => {
            this.newGroupName = value;
          })
        
        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F5F5F5')
            .layoutWeight(1)
            .height(48)
            .onClick(() => {
              this.showAddDialog = false;
              this.newGroupName = '';
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#0A59F7')
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(async () => {
              if (this.newGroupName.trim()) {
                try {
                  await StorageService.addStockGroup(this.newGroupName.trim());
                  await this.loadGroups();
                  this.showAddDialog = false;
                  this.newGroupName = '';
                  
                  promptAction.showToast({
                    message: '分组创建成功',
                    duration: 2000
                  });
                } catch (err) {
                  console.error('创建分组失败:', err);
                }
              }
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('90%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .onClick(() => {
      this.showAddDialog = false;
      this.newGroupName = '';
    })
  }

  @Builder
  buildAddStockDialog() {
    Column() {
      Blank()
      
      Column() {
        Text('添加股票')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        
        TextInput({ placeholder: '请输入股票代码，如：sh601009' })
          .width('100%')
          .height(48)
          .fontSize(16)
          .margin({ top: 24 })
          .onChange((value: string) => {
            this.newStockGid = value;
          })
        
        Text('示例：上海股市以sh开头，深圳股市以sz开头')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 8 })
        
        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor('#666666')
            .backgroundColor('#F5F5F5')
            .layoutWeight(1)
            .height(48)
            .onClick(() => {
              this.showAddStockDialog = false;
              this.newStockGid = '';
            })
          
          Button('确定')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#0A59F7')
            .layoutWeight(1)
            .height(48)
            .margin({ left: 12 })
            .onClick(async () => {
              if (this.newStockGid.trim()) {
                try {
                  await StorageService.addStockToGroup(this.selectedGroupId, this.newStockGid.trim().toLowerCase());
                  await this.loadGroups();
                  this.showAddStockDialog = false;
                  this.newStockGid = '';
                  
                  promptAction.showToast({
                    message: '股票添加成功',
                    duration: 2000
                  });
                } catch (err) {
                  console.error('添加股票失败:', err);
                }
              }
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .width('90%')
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .onClick(() => {
      this.showAddStockDialog = false;
      this.newStockGid = '';
    })
  }

  async deleteGroup(groupId: string, groupName: string) {
    try {
      await StorageService.deleteStockGroup(groupId);
      await this.loadGroups();
      
      promptAction.showToast({
        message: `分组"${groupName}"已删除`,
        duration: 2000
      });
    } catch (err) {
      console.error('删除分组失败:', err);
    }
  }

  async removeStock(groupId: string, stockGid: string) {
    try {
      await StorageService.removeStockFromGroup(groupId, stockGid);
      await this.loadGroups();
      
      promptAction.showToast({
        message: '股票已移除',
        duration: 2000
      });
    } catch (err) {
      console.error('移除股票失败:', err);
    }
  }
}
