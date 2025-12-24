// 自选股页面
import { StorageService } from '../service/StorageService';
import { StockService } from '../service/StockService';
import { StockGroup, StockInfo, SearchStockItem } from '../model/StockData';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';

interface GroupStats {
  upCount: number;
  downCount: number;
  flatCount: number;
  avgChange: string;
  totalVolume: number;
  totalAmount: number;
}

@Component
export struct FavoritePage {
  @State stockGroups: StockGroup[] = [];
  @State currentGroupIndex: number = 0;
  @State stockDataMap: Map<string, StockInfo> = new Map();
  @State isLoading: boolean = false;
  @State refreshTime: string = '';
  @State showSearchDialog: boolean = false;
  @State searchKeyword: string = '';
  @State autoRefreshEnabled: boolean = true;
  @State followGroupSwitch: boolean = false;
  @State groupStats: GroupStats | null = null;
  @State searchResults: SearchStockItem[] = [];
  @State isSearching: boolean = false;
  private refreshTimer: number = -1;
  private searchTimer: number = -1;

  async aboutToAppear() {
    // 加载存储的数据
    await this.loadSavedData();
    // 初始化统计数据
    this.groupStats = this.getGroupStats();
    // 启动自动刷新（可配置）
    this.startAutoRefresh();
  }

  startAutoRefresh() {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
    }
    
    if (this.autoRefreshEnabled) {
      this.refreshTimer = setInterval(() => {
        // 只有当前分组有股票时才刷新
        if (this.stockGroups.length > 0 && 
            this.stockGroups[this.currentGroupIndex] && 
            this.stockGroups[this.currentGroupIndex].stocks.length > 0) {
          this.loadData();
        }
      }, 30000); // 30秒刷新一次
    }
  }

  async loadSavedData() {
    try {
      // 加载股票分组
      this.stockGroups = await StorageService.getStockGroups();
      
      // 加载保存的股票数据
      const savedStockData = await StorageService.getStockDataMap();
      const savedTime = await StorageService.getStockRefreshTime();
      
      this.stockDataMap = savedStockData;
      this.refreshTime = savedTime;
      
      console.info(`从存储加载股票数据: ${savedStockData.size}只股票`);
    } catch (error) {
      console.error('加载保存的股票数据失败:', error);
    }
  }

  aboutToDisappear() {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
    }
  }

  async loadData() {
    this.isLoading = true;

    try {
      this.stockGroups = await StorageService.getStockGroups();
      console.info(`[自选股] 加载分组: ${this.stockGroups.length}个`);

      if (this.stockGroups.length > 0) {
        if (this.stockGroups[this.currentGroupIndex] &&
            this.stockGroups[this.currentGroupIndex].stocks.length > 0) {

          const stocks = this.stockGroups[this.currentGroupIndex].stocks;
          console.info(`[自选股] 当前分组股票: ${stocks.join(', ')}`);

          const newStockData = await StockService.getMultipleStocks(stocks);
          console.info(`[自选股] API返回: ${newStockData.size}只股票`);

          if (newStockData.size > 0) {
            // 获取到新数据，保存并使用
            this.stockDataMap = newStockData;
            await StorageService.saveStockDataMap(newStockData);

            const now = new Date();
            this.refreshTime = `${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`;
            await StorageService.saveStockRefreshTime(this.refreshTime);

            console.info(`[自选股] 获取成功: ${newStockData.size}只股票`);
          } else {
            // API用完或失败，使用存储的数据
            console.warn('[自选股] API返回空，使用存储的股票数据');
            const savedStockData = await StorageService.getStockDataMap();
            const savedTime = await StorageService.getStockRefreshTime();

            if (savedStockData.size > 0) {
              this.stockDataMap = savedStockData;
              this.refreshTime = savedTime || '缓存数据';
            } else {
              // 生成模拟数据
              this.generateMockStockData();
              this.refreshTime = '模拟数据';
            }
          }
        }
      }
    } catch (error) {
      console.error('[自选股] 加载数据失败:', error);
      
      // 加载失败时使用存储的数据
      const savedStockData = await StorageService.getStockDataMap();
      const savedTime = await StorageService.getStockRefreshTime();
      
      if (savedStockData.size > 0) {
        this.stockDataMap = savedStockData;
        this.refreshTime = savedTime || '缓存数据';
      } else {
        this.generateMockStockData();
        this.refreshTime = '模拟数据';
      }
    }
    
    // 更新统计数据
    this.groupStats = this.getGroupStats();
    
    this.isLoading = false;
  }

  // 生成模拟股票数据
  generateMockStockData() {
    const mockData = new Map<string, StockInfo>();
    
    if (this.stockGroups.length > 0 && this.stockGroups[this.currentGroupIndex]) {
      const stocks = this.stockGroups[this.currentGroupIndex].stocks;
      
      stocks.forEach((gid: string) => {
        const mockStock: StockInfo = {
          data: {
            gid: gid,
            name: this.getStockName(gid),
            nowPri: (Math.random() * 50 + 10).toFixed(2),
            increPer: ((Math.random() - 0.5) * 10).toFixed(2),
            increase: ((Math.random() - 0.5) * 2).toFixed(2),
            todayStartPri: (Math.random() * 50 + 10).toFixed(2),
            todayMax: (Math.random() * 50 + 10).toFixed(2),
            todayMin: (Math.random() * 50 + 10).toFixed(2),
            yestodEndPri: (Math.random() * 50 + 10).toFixed(2),
            competitivePri: (Math.random() * 50 + 10).toFixed(2),
            reservePri: (Math.random() * 50 + 10).toFixed(2),
            traNumber: Math.floor(Math.random() * 1000000).toString(),
            traAmount: Math.floor(Math.random() * 10000000).toString(),
            buyOne: (Math.random() * 50 + 10).toFixed(2),
            buyOnePri: Math.floor(Math.random() * 1000).toString(),
            buyTwo: (Math.random() * 50 + 10).toFixed(2),
            buyTwoPri: Math.floor(Math.random() * 1000).toString(),
            buyThree: (Math.random() * 50 + 10).toFixed(2),
            buyThreePri: Math.floor(Math.random() * 1000).toString(),
            buyFour: (Math.random() * 50 + 10).toFixed(2),
            buyFourPri: Math.floor(Math.random() * 1000).toString(),
            buyFive: (Math.random() * 50 + 10).toFixed(2),
            buyFivePri: Math.floor(Math.random() * 1000).toString(),
            sellOne: (Math.random() * 50 + 10).toFixed(2),
            sellOnePri: Math.floor(Math.random() * 1000).toString(),
            sellTwo: (Math.random() * 50 + 10).toFixed(2),
            sellTwoPri: Math.floor(Math.random() * 1000).toString(),
            sellThree: (Math.random() * 50 + 10).toFixed(2),
            sellThreePri: Math.floor(Math.random() * 1000).toString(),
            sellFour: (Math.random() * 50 + 10).toFixed(2),
            sellFourPri: Math.floor(Math.random() * 1000).toString(),
            sellFive: (Math.random() * 50 + 10).toFixed(2),
            sellFivePri: Math.floor(Math.random() * 1000).toString(),
            date: new Date().toLocaleDateString(),
            time: new Date().toLocaleTimeString()
          },
          gopicture: {
            minurl: '',
            dayurl: '',
            weekurl: '',
            monthurl: ''
          }
        };
        mockData.set(gid, mockStock);
      });
    }
    
    this.stockDataMap = mockData;
  }

  // 获取股票名称
  getStockName(gid: string): string {
    const nameMap: Record<string, string> = {
      'sh601009': '南京银行',
      'sh600036': '招商银行', 
      'sz000001': '平安银行',
      'sh600000': '浦发银行'
    };
    return nameMap[gid] || '未知股票';
  }

  build() {
    Column() {
      // 顶部栏
      this.buildHeader();
      
      // 分组标签
      if (this.stockGroups.length > 0) {
        this.buildGroupTabs();
        
        // 分组统计
        this.buildGroupStats();
      }
      
      // 股票列表
      this.buildStockList();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .bindContentCover(this.showSearchDialog, this.buildSearchDialog(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }

  @Builder
  buildHeader() {
    Column() {
      Row() {
        Text('自选股')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Blank()

        if (this.refreshTime) {
          Text(`${this.refreshTime}`)
            .fontSize(12)
            .fontColor(this.refreshTime === '模拟数据' ? '#FF6B35' : '#999999')
            .fontWeight(this.refreshTime === '模拟数据' ? FontWeight.Bold : FontWeight.Normal)
            .margin({ right: 12 })
        }

        // 自动刷新开关
        Row() {
          Text('自动')
            .fontSize(10)
            .fontColor(this.autoRefreshEnabled ? '#0A59F7' : '#999999')
          Toggle({ type: ToggleType.Switch, isOn: this.autoRefreshEnabled })
            .width(30)
            .height(16)
            .onChange((isOn: boolean) => {
              this.autoRefreshEnabled = isOn;
              this.startAutoRefresh();
            })
        }
        .margin({ right: 8 })

        // 刷新按钮
        Text('刷新')
          .fontSize(14)
          .fontColor('#0A59F7')
          .margin({ right: 12 })
          .onClick(() => {
            if (!this.isLoading) {
              this.loadData();
            }
          })

        // 管理按钮
        Text('管理')
          .fontSize(14)
          .fontColor('#0A59F7')
          .onClick(() => {
            router.pushUrl({ url: 'pages/GroupManage' }, router.RouterMode.Standard);
          })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })

      // 搜索框入口
      Row() {
        Text('🔍')
          .fontSize(16)
          .margin({ right: 8 })

        Text('搜索股票代码、名称或拼音首字母')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .margin({ left: 16, right: 16, bottom: 8 })
      .backgroundColor('#F5F5F5')
      .borderRadius(20)
      .onClick(() => {
        this.showSearchDialog = true;
      })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildGroupTabs() {
    Scroll() {
      Row() {
        ForEach(this.stockGroups, (group: StockGroup, index: number) => {
          Text(group.name)
            .fontSize(14)
            .fontColor(this.currentGroupIndex === index ? '#0A59F7' : '#666666')
            .fontWeight(this.currentGroupIndex === index ? FontWeight.Bold : FontWeight.Normal)
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .borderRadius(4)
            .backgroundColor(this.currentGroupIndex === index ? '#E8F2FF' : 'transparent')
            .onClick(() => {
              this.currentGroupIndex = index;
              // 更新统计数据
              this.groupStats = this.getGroupStats();
              // 如果开启跟随刷新，切换分组后自动刷新
              if (this.followGroupSwitch) {
                this.loadData();
              }
            })
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 8, bottom: 8 })
    .margin({ top: 1 })
  }

  @Builder
  buildStockList() {
    if (this.stockGroups.length === 0) {
      Column() {
        Image($r('app.media.layered_image'))
          .width(80)
          .height(80)
          .margin({ bottom: 16 })
        
        Text('暂无分组')
          .fontSize(16)
          .fontColor('#999999')
        
        Text('点击右上角"管理"创建分组')
          .fontSize(12)
          .fontColor('#CCCCCC')
          .margin({ top: 8 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.stockGroups.length > 0 && this.currentGroupIndex < this.stockGroups.length) {
      // 首次加载提示
      if (this.stockDataMap.size === 0 && !this.isLoading && this.stockGroups[this.currentGroupIndex].stocks.length > 0) {
        Column() {
          Text('暂无数据，请点击右上角"刷新"按钮获取最新股票数据')
            .fontSize(14)
            .fontColor('#666666')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#F0F8FF')
        .borderRadius(8)
        .margin(16)
      }
      
      List() {
        if (this.stockGroups[this.currentGroupIndex].stocks.length === 0) {
          ListItem() {
            Column() {
              Image($r('app.media.layered_image'))
                .width(80)
                .height(80)
                .margin({ bottom: 16 })
              
              Text('暂无自选股')
                .fontSize(16)
                .fontColor('#999999')
              
              Text('点击右上角搜索图标添加股票')
                .fontSize(12)
                .fontColor('#CCCCCC')
                .margin({ top: 8 })
            }
            .width('100%')
            .height(300)
            .justifyContent(FlexAlign.Center)
          }
        } else {
          ForEach(this.stockGroups[this.currentGroupIndex].stocks, (gid: string) => {
            ListItem() {
              this.buildStockItem(gid);
            }
            .onClick(() => {
              router.pushUrl({ 
                url: 'pages/StockDetail',
                params: { gid: gid }
              }, router.RouterMode.Standard);
            })
          })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#FFFFFF')
      .margin({ top: 8 })
      .divider({
        strokeWidth: 1,
        color: '#F5F5F5'
      })
    }
  }

  @Builder
  buildStockItem(gid: string) {
    Row() {
      Column() {
        Text(this.stockDataMap.get(gid)?.data.name || gid)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
        
        Text(gid.toUpperCase())
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      if (this.stockDataMap.get(gid)) {
        Column() {
          Text(this.stockDataMap.get(gid)!.data.nowPri)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '#E64545' : '#00B578')
          
          Row() {
            Text(`${parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '+' : ''}${this.stockDataMap.get(gid)!.data.increase}`)
              .fontSize(12)
              .fontColor(parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '#E64545' : '#00B578')
            
            Text(`${parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '+' : ''}${this.stockDataMap.get(gid)!.data.increPer}%`)
              .fontSize(12)
              .fontColor(parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '#E64545' : '#00B578')
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor(parseFloat(this.stockDataMap.get(gid)!.data.increPer) >= 0 ? '#FFEBEE' : '#E8F5E9')
              .borderRadius(2)
              .margin({ left: 6 })
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      } else {
        Text('加载中...')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  buildSearchDialog() {
    Column() {
      // 搜索框
      Column() {
        Row() {
          Image($r('app.media.layered_image'))
            .width(20)
            .height(20)
            .margin({ right: 8 })

          TextInput({ placeholder: '输入股票代码、名称或拼音首字母' })
            .layoutWeight(1)
            .backgroundColor('transparent')
            .onChange((value: string) => {
              this.searchKeyword = value;
              this.performSearch(value);
            })

          if (this.isSearching) {
            LoadingProgress()
              .width(20)
              .height(20)
              .margin({ left: 8 })
          }

          Text('取消')
            .fontSize(14)
            .fontColor('#0A59F7')
            .margin({ left: 8 })
            .onClick(() => {
              this.showSearchDialog = false;
              this.searchKeyword = '';
              this.searchResults = [];
            })
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ top: 16, left: 16, right: 16 })

        // 搜索中状态
        if (this.isSearching) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
            Text(`正在搜索 "${this.searchKeyword}"...`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        }
        // 搜索结果列表
        else if (this.searchResults.length > 0) {
          Column() {
            Text(`找到 ${this.searchResults.length} 个结果`)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 16, top: 8, bottom: 4 })
              .width('100%')

            List() {
              ForEach(this.searchResults, (item: SearchStockItem) => {
                ListItem() {
                  this.buildSearchResultItem(item);
                }
                .onClick(() => {
                  this.addStockFromSearch(item);
                })
              })
            }
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .divider({ strokeWidth: 1, color: '#F0F0F0' })
          }
          .width('100%')
          .height(400)
        } else if (this.searchKeyword.trim() && !this.isSearching) {
          // 无结果提示
          Column() {
            Text('😕')
              .fontSize(40)
              .margin({ bottom: 12 })

            Text(`未找到 "${this.searchKeyword}" 相关股票`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 16 })

            Text('请尝试：')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 8 })

            Column() {
              Text('• 输入完整股票代码，如 600519')
                .fontSize(12)
                .fontColor('#999999')
              Text('• 输入股票名称，如 贵州茅台')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
              Text('• 输入拼音首字母，如 gzmt')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(32)
          .justifyContent(FlexAlign.Center)
        } else if (!this.searchKeyword.trim()) {
          // 默认提示
          Column() {
            Text('搜索说明')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .margin({ bottom: 12 })

            Column() {
              this.buildSearchTip('股票代码', '直接输入6位数字', '600519');
              this.buildSearchTip('股票名称', '输入中文名称', '贵州茅台');
              this.buildSearchTip('拼音首字母', '输入拼音首字母', 'gzmt / payh');
            }

            Text('支持A股、港股、美股搜索')
              .fontSize(12)
              .fontColor('#666666')
              .margin({ top: 16 })
          }
          .width('100%')
          .padding(16)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 12, topRight: 12 })
      .margin({ top: 60 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
  }

  @Builder
  buildSearchResultItem(item: SearchStockItem) {
    Row() {
      Column() {
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontColor('#1A1A1A')
            .fontWeight(FontWeight.Medium)

          Text(item.financeType === 'index' ? '指数' : (item.financeType === 'fund' ? '基金' : ''))
            .fontSize(10)
            .fontColor('#FFFFFF')
            .backgroundColor(item.financeType === 'index' ? '#FF9800' : '#2196F3')
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(2)
            .margin({ left: 6 })
            .visibility(item.financeType !== 'stock' ? Visibility.Visible : Visibility.None)
        }

        Text(`${item.exchange}${item.code}`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(item.price || '--')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPriceColor(item.ratio))

        Text(item.ratio || '--')
          .fontSize(12)
          .fontColor(this.getPriceColor(item.ratio))
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)

      Image($r('app.media.layered_image'))
        .width(20)
        .height(20)
        .margin({ left: 12 })
        .fillColor('#0A59F7')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  getPriceColor(ratio: string): string {
    if (!ratio) return '#333333';
    if (ratio.startsWith('+')) return '#E64545';
    if (ratio.startsWith('-')) return '#00B578';
    return '#333333';
  }

  // 执行搜索 - 每输入一个字符就搜索
  performSearch(keyword: string) {
    // 清除之前的定时器
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }

    const trimmed = keyword.trim();
    if (!trimmed) {
      this.searchResults = [];
      this.isSearching = false;
      return;
    }

    // 立即显示搜索中状态
    this.isSearching = true;

    // 防抖100ms，避免请求过于频繁
    this.searchTimer = setTimeout(async () => {
      console.info(`开始搜索: ${trimmed}`);
      try {
        const results = await StockService.searchStock(trimmed);
        console.info(`搜索结果: ${results.length}条`);
        // 只有当搜索关键词没变时才更新结果
        if (this.searchKeyword.trim() === trimmed) {
          this.searchResults = results;
        }
      } catch (error) {
        console.error('搜索失败:', error);
        this.searchResults = [];
      }
      this.isSearching = false;
    }, 100);
  }

  // 从搜索结果添加股票
  async addStockFromSearch(item: SearchStockItem) {
    try {
      if (this.stockGroups.length === 0) {
        promptAction.showToast({
          message: '请先创建分组',
          duration: 2000
        });
        this.showSearchDialog = false;
        router.pushUrl({ url: 'pages/GroupManage' }, router.RouterMode.Standard);
        return;
      }

      const gid = StockService.convertToGid(item);
      const currentGroup = this.stockGroups[this.currentGroupIndex];

      if (currentGroup.stocks.includes(gid)) {
        promptAction.showToast({
          message: '该股票已在自选中',
          duration: 2000
        });
        return;
      }

      await StorageService.addStockToGroup(currentGroup.id, gid);
      this.stockGroups = await StorageService.getStockGroups();

      this.showSearchDialog = false;
      this.searchKeyword = '';
      this.searchResults = [];

      promptAction.showToast({
        message: `已添加 ${item.name}，请点击刷新获取数据`,
        duration: 2000
      });
    } catch (err) {
      console.error('添加股票失败:', err);
      promptAction.showToast({
        message: '添加失败，请重试',
        duration: 2000
      });
    }
  }

  @Builder
  buildSearchTip(title: string, format: string, example: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(14)
          .fontColor('#1A1A1A')
        
        Text(format)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Text(example)
        .fontSize(12)
        .fontColor('#0A59F7')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F8F8F8')
    .borderRadius(8)
    .margin({ bottom: 8 })
  }

  async addStock() {
    try {
      const stockCode = this.searchKeyword.trim().toLowerCase();
      
      if (!stockCode) {
        promptAction.showToast({
          message: '请输入股票代码',
          duration: 2000
        });
        return;
      }
      
      // 验证格式
      if (!stockCode.startsWith('sh') && !stockCode.startsWith('sz')) {
        promptAction.showToast({
          message: '股票代码格式错误，必须以sh或sz开头',
          duration: 2000
        });
        return;
      }
      
      if (this.stockGroups.length === 0) {
        promptAction.showToast({
          message: '请先创建分组',
          duration: 2000
        });
        this.showSearchDialog = false;
        router.pushUrl({ url: 'pages/GroupManage' }, router.RouterMode.Standard);
        return;
      }
      
      const currentGroup = this.stockGroups[this.currentGroupIndex];
      
      if (currentGroup.stocks.includes(stockCode)) {
        promptAction.showToast({
          message: '该股票已在自选中',
          duration: 2000
        });
        return;
      }
      
      await StorageService.addStockToGroup(currentGroup.id, stockCode);
      // 移除自动加载，提示用户手动刷新
      this.stockGroups = await StorageService.getStockGroups();
      
      this.showSearchDialog = false;
      this.searchKeyword = '';
      
      promptAction.showToast({
        message: '添加成功，请点击刷新获取数据',
        duration: 2000
      });
    } catch (err) {
      console.error('添加股票失败:', err);
      promptAction.showToast({
        message: '添加失败，请重试',
        duration: 2000
      });
    }
  }

  // 计算分组统计数据
  private getGroupStats(): GroupStats | null {
    if (this.stockGroups.length === 0 || this.currentGroupIndex >= this.stockGroups.length) {
      return null;
    }

    const currentGroup = this.stockGroups[this.currentGroupIndex];
    const groupStocks = currentGroup.stocks;
    
    if (groupStocks.length === 0) {
      return null;
    }

    let upCount = 0;
    let downCount = 0;
    let flatCount = 0;
    let totalChange = 0;
    let totalVolume = 0;
    let totalAmount = 0;

    groupStocks.forEach((gid: string) => {
      const stockData = this.stockDataMap.get(gid);
      if (stockData) {
        const changePercent = parseFloat(stockData.data.increPer);
        if (changePercent > 0) {
          upCount++;
        } else if (changePercent < 0) {
          downCount++;
        } else {
          flatCount++;
        }
        totalChange += changePercent;
        totalVolume += parseFloat(stockData.data.traNumber) || 0;
        totalAmount += parseFloat(stockData.data.traAmount) || 0;
      }
    });

    const avgChange = groupStocks.length > 0 ? (totalChange / groupStocks.length).toFixed(2) : '0.00';
    
    const result: GroupStats = {
      upCount: upCount,
      downCount: downCount,
      flatCount: flatCount,
      avgChange: avgChange,
      totalVolume: totalVolume,
      totalAmount: totalAmount
    };
    return result;
  }

  @Builder
  buildGroupStats() {
    if (this.groupStats) {
      Row() {
        // 涨跌统计
        Column() {
          Text('涨跌分布')
            .fontSize(10)
            .fontColor('#666666')
          
          Row() {
            Text(`↑${this.groupStats.upCount}`)
              .fontSize(12)
              .fontColor('#E64545')
              .margin({ right: 8 })
            
            Text(`↓${this.groupStats.downCount}`)
              .fontSize(12)
              .fontColor('#00B578')
              .margin({ right: 8 })
            
            Text(`→${this.groupStats.flatCount}`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        // 平均涨跌幅
        Column() {
          Text('平均涨跌')
            .fontSize(10)
            .fontColor('#666666')
          
          Text(`${parseFloat(this.groupStats.avgChange) >= 0 ? '+' : ''}${this.groupStats.avgChange}%`)
            .fontSize(12)
            .fontColor(parseFloat(this.groupStats.avgChange) >= 0 ? '#E64545' : '#00B578')
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        
        // 总成交量
        Column() {
          Text('总成交量')
            .fontSize(10)
            .fontColor('#666666')
          
          Text(`${(this.groupStats.totalVolume / 10000).toFixed(0)}万`)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        
        // 总成交额
        Column() {
          Text('总成交额')
            .fontSize(10)
            .fontColor('#666666')
          
          Text(`${(this.groupStats.totalAmount / 100000000).toFixed(1)}亿`)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#F8F8F8')
      .margin({ top: 1 })
    }
  }
}
