// 股票行情桌面卡片
import formBindingData from '@ohos.app.form.formBindingData';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formInfo from '@ohos.app.form.formInfo';
import formProvider from '@ohos.app.form.formProvider';
import Want from '@ohos.app.ability.Want';
import type { Configuration } from '@ohos.app.ability.Configuration';
import { StockService } from '../service/StockService';
import { StorageService } from '../service/StorageService';
import { IndexData, StockInfo } from '../model/StockData';

export default class StockWidgetCard extends FormExtensionAbility {
  onAddForm(want: Want) {
    console.info('[StockWidget] onAddForm');
    
    // 获取卡片配置
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string;
    const tempFlag = want.parameters?.[formInfo.FormParam.TEMPORARY_KEY] as boolean;
    
    console.info(`[StockWidget] FormId: ${formId}, FormName: ${formName}, TempFlag: ${tempFlag}`);
    
    // 返回初始数据
    const formData: Record<string, string | boolean> = {
      'title': '股票行情',
      'updateTime': new Date().toLocaleTimeString(),
      'shIndex': '加载中...',
      'shChange': '0.00%',
      'szIndex': '加载中...',
      'szChange': '0.00%',
      'isLoading': true
    };
    
    // 立即更新数据
    this.updateFormData(formId);
    
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    console.info('[StockWidget] onCastToNormalForm');
  }

  onUpdateForm(formId: string) {
    console.info('[StockWidget] onUpdateForm');
    this.updateFormData(formId);
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    console.info('[StockWidget] onChangeFormVisibility');
  }

  onFormEvent(formId: string, message: string) {
    console.info(`[StockWidget] onFormEvent: ${message}`);
    
    // 处理卡片点击事件
    if (message === 'router') {
      // 跳转到主应用
      console.info('[StockWidget] Router to main app');
    } else if (message === 'refresh') {
      // 手动刷新
      this.updateFormData(formId);
    }
  }

  onRemoveForm(formId: string) {
    console.info('[StockWidget] onRemoveForm');
  }

  onConfigurationUpdate(newConfig: Configuration) {
    console.info('[StockWidget] onConfigurationUpdate');
  }

  onAcquireFormState(want: Want) {
    console.info('[StockWidget] onAcquireFormState');
    return formInfo.FormState.READY;
  }

  // 更新卡片数据
  private async updateFormData(formId: string) {
    try {
      console.info(`[StockWidget] Updating form data for ${formId}`);
      
      // 获取指数数据
      const shIndex = await StockService.getIndexData(0);
      const szIndex = await StockService.getIndexData(1);
      
      let formData: Record<string, Object>;
      
      if (shIndex && szIndex) {
        // 获取到新数据
        formData = {
          'title': '股票行情',
          'updateTime': new Date().toLocaleTimeString(),
          'shIndex': shIndex.nowpri,
          'shChange': `${parseFloat(shIndex.increPer) >= 0 ? '+' : ''}${shIndex.increPer}%`,
          'shChangeColor': parseFloat(shIndex.increPer) >= 0 ? '#E64545' : '#00B578',
          'szIndex': szIndex.nowpri,
          'szChange': `${parseFloat(szIndex.increPer) >= 0 ? '+' : ''}${szIndex.increPer}%`,
          'szChangeColor': parseFloat(szIndex.increPer) >= 0 ? '#E64545' : '#00B578',
          'isLoading': false
        };
      } else {
        // API失败，使用缓存数据
        const savedShData = await StorageService.getShIndexData();
        const savedSzData = await StorageService.getSzIndexData();
        
        if (savedShData && savedSzData) {
          formData = {
            'title': '股票行情(缓存)',
            'updateTime': await StorageService.getIndexRefreshTime() || '缓存数据',
            'shIndex': savedShData.nowpri,
            'shChange': `${parseFloat(savedShData.increPer) >= 0 ? '+' : ''}${savedShData.increPer}%`,
            'shChangeColor': parseFloat(savedShData.increPer) >= 0 ? '#E64545' : '#00B578',
            'szIndex': savedSzData.nowpri,
            'szChange': `${parseFloat(savedSzData.increPer) >= 0 ? '+' : ''}${savedSzData.increPer}%`,
            'szChangeColor': parseFloat(savedSzData.increPer) >= 0 ? '#E64545' : '#00B578',
            'isLoading': false
          };
        } else {
          // 没有缓存数据，生成模拟数据
          const mockShPrice = 3200 + Math.random() * 200;
          const mockShChange = (Math.random() - 0.5) * 4;
          const mockSzPrice = 11000 + Math.random() * 1000;
          const mockSzChange = (Math.random() - 0.5) * 4;
          
          formData = {
            'title': '股票行情(模拟)',
            'updateTime': '模拟数据',
            'shIndex': mockShPrice.toFixed(2),
            'shChange': `${mockShChange >= 0 ? '+' : ''}${mockShChange.toFixed(2)}%`,
            'shChangeColor': mockShChange >= 0 ? '#E64545' : '#00B578',
            'szIndex': mockSzPrice.toFixed(2),
            'szChange': `${mockSzChange >= 0 ? '+' : ''}${mockSzChange.toFixed(2)}%`,
            'szChangeColor': mockSzChange >= 0 ? '#E64545' : '#00B578',
            'isLoading': false
          };
        }
      }
      
      // 更新卡片
      const bindingData = formBindingData.createFormBindingData(formData);
      await formProvider.updateForm(formId, bindingData);
      
      console.info('[StockWidget] Form data updated successfully');
    } catch (error) {
      console.error('[StockWidget] Update form data failed:', error);
    }
  }
}
