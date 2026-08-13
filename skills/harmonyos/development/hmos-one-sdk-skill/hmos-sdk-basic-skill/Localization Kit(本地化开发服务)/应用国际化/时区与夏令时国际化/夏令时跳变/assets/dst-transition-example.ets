import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface DSTCalculationResult {
  hoursDifference: number;
  startTime: number;
  finishTime: number;
  timezone: string;
  isDSTActive: boolean;
}

interface DSTTransitionInfo {
  transitionTime: Date;
  isForward: boolean;
  hoursSkipped: number;
}

class DSTTransitionCalculator {
  private calendar: i18n.Calendar;
  private timezone: string;

  constructor(timezone: string = 'Europe/London') {
    this.calendar = i18n.getCalendar('zh-Hans');
    this.setTimezone(timezone);
  }

  setTimezone(timezone: string): void {
    const validTimezones: string[] = [
      'Europe/London', 'Europe/Paris', 'Europe/Berlin',
      'America/New_York', 'America/Los_Angeles', 'America/Chicago',
      'Asia/Shanghai', 'Asia/Tokyo', 'Australia/Sydney'
    ];

    if (!validTimezones.includes(timezone)) {
      console.warn(`警告: 时区 "${timezone}" 可能不支持夏令时`);
    }

    this.timezone = timezone;
    this.calendar.setTimeZone(timezone);
  }

  calculateDSTHoursDifference(
    year: number,
    startMonth: number,
    startDay: number,
    endMonth: number,
    endDay: number
  ): DSTCalculationResult {
    try {
      this.calendar.set(year, startMonth, startDay, 16, 0, 0);
      const startTime = this.calendar.getTimeInMillis();

      this.calendar.set(year, endMonth, endDay, 16, 0, 0);
      const finishTime = this.calendar.getTimeInMillis();

      const hoursDifference = (finishTime - startTime) / (3600 * 1000);

      this.calendar.set(year, endMonth, endDay, 16, 0, 0);
      const dstOffset = this.calendar.get('dst_offset');
      const isDSTActive = dstOffset !== 0;

      return {
        hoursDifference: hoursDifference,
        startTime: startTime,
        finishTime: finishTime,
        timezone: this.timezone,
        isDSTActive: isDSTActive
      };
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`计算夏令时时间差失败 [错误码: ${err.code}]: ${err.message}`);
      throw error;
    }
  }

  detectDSTTransition(year: number, month: number, day: number): DSTTransitionInfo | null {
    try {
      const checkTimeRange = (startHour: number, endHour: number): number => {
        for (let hour = startHour; hour <= endHour; hour++) {
          this.calendar.set(year, month, day, hour, 0, 0);
          const timestamp1 = this.calendar.getTimeInMillis();

          this.calendar.set(year, month, day, hour + 1, 0, 0);
          const timestamp2 = this.calendar.getTimeInMillis();

          const actualHours = (timestamp2 - timestamp1) / (3600 * 1000);

          if (Math.abs(actualHours - 1) > 0.01) {
            return hour;
          }
        }
        return -1;
      };

      const transitionHour = checkTimeRange(0, 23);

      if (transitionHour >= 0) {
        this.calendar.set(year, month, day, transitionHour, 0, 0);
        const timestamp1 = this.calendar.getTimeInMillis();

        this.calendar.set(year, month, day, transitionHour + 1, 0, 0);
        const timestamp2 = this.calendar.getTimeInMillis();

        const actualHours = (timestamp2 - timestamp1) / (3600 * 1000);

        return {
          transitionTime: new Date(this.calendar.getTimeInMillis()),
          isForward: actualHours < 0,
          hoursSkipped: Math.abs(actualHours - 1)
        };
      }

      return null;
    } catch (error) {
      console.error(`检测夏令时跳变失败: ${error}`);
      return null;
    }
  }

  isDST(timestamp: number): boolean {
    this.calendar.setTime(timestamp);
    const dstOffset = this.calendar.get('dst_offset');
    return dstOffset !== 0;
  }

  getDSTInfo(timestamp: number): object {
    this.calendar.setTime(timestamp);

    const year = this.calendar.get('year');
    const month = this.calendar.get('month');
    const day = this.calendar.get('date');
    const hour = this.calendar.get('hour_of_day');
    const minute = this.calendar.get('minute');
    const second = this.calendar.get('second');
    const dstOffset = this.calendar.get('dst_offset');
    const zoneOffset = this.calendar.get('zone_offset');

    return {
      localTime: `${year}-${month + 1}-${day} ${hour}:${minute}:${second}`,
      timezone: this.timezone,
      isDST: dstOffset !== 0,
      dstOffset: dstOffset,
      zoneOffset: zoneOffset,
      totalOffset: zoneOffset + dstOffset
    };
  }

  convertToUTC(localTimestamp: number): number {
    this.calendar.setTime(localTimestamp);
    return this.calendar.getTimeInMillis();
  }

  convertFromUTC(utcTimestamp: number, targetTimezone: string): number {
    const tempCalendar = i18n.getCalendar('zh-Hans');
    tempCalendar.setTimeZone(targetTimezone);
    tempCalendar.setTime(utcTimestamp);
    return tempCalendar.getTimeInMillis();
  }
}

export { DSTTransitionCalculator, DSTCalculationResult, DSTTransitionInfo };

const calculator = new DSTTransitionCalculator('Europe/London');

const result = calculator.calculateDSTHoursDifference(2021, 2, 27, 2, 28);
console.log(`夏令时跳变时间差: ${result.hoursDifference} 小时`);
console.log(`夏令时是否激活: ${result.isDSTActive}`);

const transition = calculator.detectDSTTransition(2021, 2, 28);
if (transition) {
  console.log(`检测到夏令时跳变:`);
  console.log(`  跳变时间: ${transition.transitionTime}`);
  console.log(`  是否向前跳: ${transition.isForward}`);
  console.log(`  跳过小时数: ${transition.hoursSkipped}`);
}

const timestamp = Date.now();
const isDST = calculator.isDST(timestamp);
console.log(`当前时间是否在夏令时: ${isDST}`);

const dstInfo = calculator.getDSTInfo(timestamp);
console.log(`夏令时详细信息:`, dstInfo);

const utcTime = calculator.convertToUTC(timestamp);
console.log(`UTC时间戳: ${utcTime}`);