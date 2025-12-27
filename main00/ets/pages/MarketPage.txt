// 行情页面 - 显示大盘指数
import { StockService } from '../service/StockService';
import { IndexData } from '../model/StockData';
import { StorageService } from '../service/StorageService';
import router from '@ohos.router';

// 定义价格点接口
interface PricePoint {
  x: number;
  y: number;
  isUp: boolean;
}

@Component
export struct MarketPage {
  @State shIndexData: IndexData | null = null;
  @State szIndexData: IndexData | null = null;
  @State isLoading: boolean = false;
  @State refreshTime: string = '';
  @State errorMessage: string = '';
  private refreshTimer: number = -1;

  aboutToAppear() {
    // 从本地存储加载保存的数据
    this.loadSavedData();
    // 首次进入立即拉取一次
    this.loadData();
    // 启动定时刷新（60s）
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
    }
    this.refreshTimer = setInterval(() => {
      // 交易时段高频刷新，非交易时段也允许刷新以显示缓存/模拟
      this.loadData();
    }, 60000);
  }

  async loadSavedData() {
    try {
      // 加载保存的指数数据
      const shData = await StorageService.getShIndexData();
      const szData = await StorageService.getSzIndexData();
      const savedTime = await StorageService.getIndexRefreshTime();
      
      this.shIndexData = shData;
      this.szIndexData = szData;
      this.refreshTime = savedTime;
      
      console.info(`从存储加载数据: 上证=${shData?.nowpri}, 深证=${szData?.nowpri}`);
    } catch (error) {
      console.error('加载保存数据失败:', error);
    }
  }

  aboutToDisappear() {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
    }
  }

  async loadData() {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      console.info('开始加载指数数据...');
      const shIndex = await StockService.getIndexData(0);
      const szIndex = await StockService.getIndexData(1);
      
      if (!shIndex && !szIndex) {
        // API次数用完，使用存储的真实数据
        console.warn('API次数用完，使用存储的真实数据');
        
        const savedShData = await StorageService.getShIndexData();
        const savedSzData = await StorageService.getSzIndexData();
        
        if (savedShData || savedSzData) {
          // 有存储的真实数据，直接使用
          this.shIndexData = savedShData;
          this.szIndexData = savedSzData;
          
          // 更新时间显示为上次更新时间
          const savedTime = await StorageService.getIndexRefreshTime();
          this.refreshTime = savedTime || '数据已缓存';
        } else {
          // 没有存储数据，使用模拟数据但不显示错误
          const mockShData: IndexData = {
            name: '上证指数',
            nowpri: '3994.15',
            increPer: '-0.22',
            increase: '-8.63',
            openPri: '3996.56',
            highPri: '4020.38',
            lowpri: '3980.68',
            yesPri: '4002.76',
            time: new Date().toLocaleString(),
            dealNum: '469465204',
            dealPri: '668061774921'
          };
          
          const mockSzData: IndexData = {
            name: '深证成指',
            nowpri: '13217.89',
            increPer: '-0.54',
            increase: '-71.61',
            openPri: '13240.70',
            highPri: '13312.53',
            lowpri: '13120.71',
            yesPri: '13289.01',
            time: new Date().toLocaleString(),
            dealNum: '59062140564',
            dealPri: '886975713250.337'
          };
          
          this.shIndexData = mockShData;
          this.szIndexData = mockSzData;
          this.refreshTime = '模拟数据';
        }
      } else {
        // 正常获取到数据
        this.shIndexData = shIndex;
        this.szIndexData = szIndex;
        
        // 保存真实数据到本地存储
        if (shIndex) {
          await StorageService.saveShIndexData(shIndex);
        }
        if (szIndex) {
          await StorageService.saveSzIndexData(szIndex);
        }
        
        const now = new Date();
        this.refreshTime = `${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`;
        await StorageService.saveIndexRefreshTime(this.refreshTime);
      }
      
      console.info(`数据加载完成: 上证=${this.shIndexData?.nowpri}, 深证=${this.szIndexData?.nowpri}`);
    } catch (error) {
      console.error('加载数据失败:', error);
      
      // 加载失败时使用存储的数据，不显示错误
      const savedShData = await StorageService.getShIndexData();
      const savedSzData = await StorageService.getSzIndexData();
      
      if (savedShData || savedSzData) {
        this.shIndexData = savedShData;
        this.szIndexData = savedSzData;
        const savedTime = await StorageService.getIndexRefreshTime();
        this.refreshTime = savedTime || '缓存数据';
      }
    }
    
    this.isLoading = false;
  }

  // 判断是否在A股交易时段（用于后续优化刷新策略）
  isTradingTime(): boolean {
    const now = new Date();
    const day = now.getDay(); // 0 周日, 6 周六
    if (day === 0 || day === 6) return false;
    const minutes = now.getHours() * 60 + now.getMinutes();
    const session1Start = 9 * 60 + 15; // 09:15
    const session1End = 11 * 60 + 30;  // 11:30
    const session2Start = 13 * 60 + 0; // 13:00
    const session2End = 15 * 60 + 0;   // 15:00
    return (minutes >= session1Start && minutes <= session1End) ||
           (minutes >= session2Start && minutes <= session2End);
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('市场行情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
        
        Text(`更新: ${this.refreshTime}`)
          .fontSize(12)
          .fontColor(this.refreshTime === '模拟数据' ? '#FF6B35' : '#999999')
          .fontWeight(this.refreshTime === '模拟数据' ? FontWeight.Bold : FontWeight.Normal)
          .margin({ right: 8 })
        
        Text('刷新')
          .fontSize(14)
          .fontColor('#007AFF')
          .onClick(() => {
            this.loadData();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      Scroll() {
        Column() {
          // 加载状态
          if (this.isLoading) {
            Row() {
              Text('正在加载...')
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
          
          // 首次加载提示
          if (!this.shIndexData && !this.szIndexData && !this.isLoading) {
            Row() {
              Text('暂无数据，请点击右上角"刷新"按钮获取最新行情')
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
          
          // 大盘指数 - 简化显示
          if (this.shIndexData) {
            Column() {
              Text('上证指数')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })
              
              Text(`当前: ${this.shIndexData.nowpri}`)
                .fontSize(20)
                .fontColor('#E64545')
                .margin({ bottom: 4 })
              
              Text(`涨跌: ${this.shIndexData.increase} (${this.shIndexData.increPer}%)`)
                .fontSize(14)
                .fontColor('#E64545')
                .margin({ bottom: 8 })
              
              // 简单的趋势图表
              this.buildTrendChart(this.shIndexData)
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .width('100%')
            .margin({ bottom: 8 })
          }
          
          if (this.szIndexData) {
            Column() {
              Text('深证成指')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 8 })
              
              Text(`当前: ${this.szIndexData.nowpri}`)
                .fontSize(20)
                .fontColor('#E64545')
                .margin({ bottom: 4 })
              
              Text(`涨跌: ${this.szIndexData.increase} (${this.szIndexData.increPer}%)`)
                .fontSize(14)
                .fontColor('#E64545')
                .margin({ bottom: 8 })
              
              // 简单的趋势图表
              this.buildTrendChart(this.szIndexData)
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .width('100%')
          }
        }
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTrendChart(indexData: IndexData) {
    Column() {
      // K线图标题
      Row() {
        Text('分时走势')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Text('今日')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      // 模拟K线图区域
      Column() {
        // 价格网格线和折线图
        Stack() {
          // 背景网格
          Column() {
            ForEach([1, 2, 3, 4], (item: number) => {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor('#F0F0F0')
                .margin({ bottom: 20 })
            })
          }
          .width('100%')
          .height(120)
          
          // 模拟折线图
          this.buildLineChart(indexData)
        }
        .width('100%')
        .height(120)
        .padding(8)
        
        // 价格标签
        Row() {
          Text(indexData.lowpri)
            .fontSize(10)
            .fontColor('#4CAF50')
          
          Blank()
          
          Text(indexData.nowpri)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(parseFloat(indexData.increPer) < 0 ? '#E64545' : '#4CAF50')
          
          Blank()
          
          Text(indexData.highPri)
            .fontSize(10)
            .fontColor('#FF6B6B')
        }
        .width('100%')
        .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .backgroundColor('#FAFAFA')
      .borderRadius(8)
      .padding(8)
      
      // 交易数据
      Row() {
        Column() {
          Text('成交量')
            .fontSize(10)
            .fontColor('#999999')
          Text(`${(parseFloat(indexData.dealNum) / 100000000).toFixed(2)}亿`)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column() {
          Text('成交额')
            .fontSize(10)
            .fontColor('#999999')
          Text(`${(parseFloat(indexData.dealPri) / 100000000).toFixed(0)}亿`)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column() {
          Text('振幅')
            .fontSize(10)
            .fontColor('#999999')
          Text(`${((parseFloat(indexData.highPri) - parseFloat(indexData.lowpri)) / parseFloat(indexData.yesPri) * 100).toFixed(2)}%`)
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column() {
          Text('换手')
            .fontSize(10)
            .fontColor('#999999')
          Text('0.85%')
            .fontSize(12)
            .fontColor('#333333')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(6)
      .margin({ top: 8 })
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  buildLineChart(indexData: IndexData) {
    // 模拟分时走势线
    Row() {
      // 生成模拟的价格点
      ForEach(this.generateMockPricePoints(indexData), (point: PricePoint, index: number) => {
        Column() {
          // 价格点
          Row()
            .width(2)
            .height(2)
            .backgroundColor(point.isUp ? '#4CAF50' : '#E64545')
            .borderRadius(1)
            .margin({ top: point.y })
          
          // 连接线（简化版）
          if (index < 29) {
            Row()
              .width(1)
              .height(8)
              .backgroundColor(point.isUp ? '#4CAF50' : '#E64545')
              .opacity(0.3)
          }
        }
        .layoutWeight(1)
        .height('100%')
      })
    }
    .width('100%')
    .height('100%')
  }

  // 生成模拟价格点数据
  generateMockPricePoints(indexData: IndexData): Array<PricePoint> {
    const points: Array<PricePoint> = [];
    const basePrice = parseFloat(indexData.nowpri);
    const isUpTrend = parseFloat(indexData.increPer) >= 0;
    
    for (let i = 0; i < 30; i++) {
      // 模拟价格波动
      const variation = (Math.random() - 0.5) * 0.02; // ±2%的随机波动
      const trendFactor = isUpTrend ? 0.001 : -0.001; // 趋势因子
      const price = basePrice * (1 + variation + trendFactor * i);
      
      // 将价格映射到Y坐标 (0-100)
      const minPrice = parseFloat(indexData.lowpri);
      const maxPrice = parseFloat(indexData.highPri);
      const y = 100 - ((price - minPrice) / (maxPrice - minPrice)) * 100;
      
      const point: PricePoint = {
        x: i,
        y: Math.max(0, Math.min(100, y)),
        isUp: i === 0 ? isUpTrend : price > (points[i-1] ? basePrice : price)
      };
      points.push(point);
    }
    
    return points;
  }
}
