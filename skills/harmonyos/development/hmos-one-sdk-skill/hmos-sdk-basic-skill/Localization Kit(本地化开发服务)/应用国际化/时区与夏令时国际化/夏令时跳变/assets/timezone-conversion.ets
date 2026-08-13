import { i18n } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface TimeZoneConversionResult {
  sourceTime: Date;
  sourceTimezone: string;
  targetTime: Date;
  targetTimezone: string;
  utcTimestamp: number;
  sourceIsDST: boolean;
  targetIsDST: boolean;
}

interface MultiTimeZoneTime {
  timezone: string;
  localTime: string;
  isDST: boolean;
  offset: number;
  utcTimestamp: number;
}

class TimeZoneConverter {
  private commonTimezones: string[] = [
    'UTC',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Asia/Hong_Kong',
    'Australia/Sydney',
    'Pacific/Auckland'
  ];

  convertTimeBetweenZones(
    sourceTime: Date,
    sourceTimezone: string,
    targetTimezone: string
  ): TimeZoneConversionResult {
    try {
      const sourceCalendar = i18n.getCalendar('zh-Hans');
      sourceCalendar.setTimeZone(sourceTimezone);
      sourceCalendar.set(
        sourceTime.getFullYear(),
        sourceTime.getMonth(),
        sourceTime.getDate(),
        sourceTime.getHours(),
        sourceTime.getMinutes(),
        sourceTime.getSeconds()
      );

      const utcTimestamp = sourceCalendar.getTimeInMillis();
      const sourceDstOffset = sourceCalendar.get('dst_offset');
      const sourceIsDST = sourceDstOffset !== 0;

      const targetCalendar = i18n.getCalendar('zh-Hans');
      targetCalendar.setTimeZone(targetTimezone);
      targetCalendar.setTime(utcTimestamp);

      const targetDstOffset = targetCalendar.get('dst_offset');
      const targetIsDST = targetDstOffset !== 0;

      const targetYear = targetCalendar.get('year');
      const targetMonth = targetCalendar.get('month');
      const targetDay = targetCalendar.get('date');
      const targetHour = targetCalendar.get('hour_of_day');
      const targetMinute = targetCalendar.get('minute');
      const targetSecond = targetCalendar.get('second');

      const targetTime = new Date(
        targetYear,
        targetMonth,
        targetDay,
        targetHour,
        targetMinute,
        targetSecond
      );

      return {
        sourceTime: sourceTime,
        sourceTimezone: sourceTimezone,
        targetTime: targetTime,
        targetTimezone: targetTimezone,
        utcTimestamp: utcTimestamp,
        sourceIsDST: sourceIsDST,
        targetIsDST: targetIsDST
      };
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`时区转换失败 [错误码: ${err.code}]: ${err.message}`);
      throw error;
    }
  }

  getTimeInMultipleZones(time: Date): MultiTimeZoneTime[] {
    const results: MultiTimeZoneTime[] = [];

    for (const timezone of this.commonTimezones) {
      try {
        const calendar = i18n.getCalendar('zh-Hans');
        calendar.setTimeZone(timezone);
        calendar.set(
          time.getFullYear(),
          time.getMonth(),
          time.getDate(),
          time.getHours(),
          time.getMinutes(),
          time.getSeconds()
        );

        const utcTimestamp = calendar.getTimeInMillis();
        const year = calendar.get('year');
        const month = calendar.get('month');
        const day = calendar.get('date');
        const hour = calendar.get('hour_of_day');
        const minute = calendar.get('minute');
        const second = calendar.get('second');

        const dstOffset = calendar.get('dst_offset');
        const zoneOffset = calendar.get('zone_offset');
        const totalOffset = zoneOffset + dstOffset;

        results.push({
          timezone: timezone,
          localTime: `${year}-${month + 1}-${day} ${hour}:${minute}:${second}`,
          isDST: dstOffset !== 0,
          offset: totalOffset,
          utcTimestamp: utcTimestamp
        });
      } catch (error) {
        console.warn(`时区 ${timezone} 处理失败，跳过`);
      }
    }

    return results;
  }

  findBestMeetingTime(
    participantTimezones: string[],
    preferredHours: number[] = [9, 10, 11, 14, 15, 16, 17]
  ): object {
    const bestSlots: object[] = [];

    for (let day = 1; day <= 7; day++) {
      for (const hour of preferredHours) {
        let allInGoodHours = true;
        const timeSlots: object[] = [];

        for (const timezone of participantTimezones) {
          const calendar = i18n.getCalendar('zh-Hans');
          calendar.setTimeZone(timezone);
          calendar.set(2021, 0, day, hour, 0, 0);

          const localHour = calendar.get('hour_of_day');
          const isDST = calendar.get('dst_offset') !== 0;

          if (localHour < 8 || localHour > 18) {
            allInGoodHours = false;
            break;
          }

          timeSlots.push({
            timezone: timezone,
            localHour: localHour,
            isDST: isDST
          });
        }

        if (allInGoodHours) {
          bestSlots.push({
            utcHour: hour,
            day: day,
            participantTimes: timeSlots
          });
        }
      }
    }

    return {
      recommendedSlots: bestSlots.slice(0, 5),
      participantTimezones: participantTimezones
    };
  }

  formatTimeWithDSTIndicator(time: Date, timezone: string, locale: string = 'zh-CN'): string {
    const calendar = i18n.getCalendar(locale);
    calendar.setTimeZone(timezone);
    calendar.set(
      time.getFullYear(),
      time.getMonth(),
      time.getDate(),
      time.getHours(),
      time.getMinutes(),
      time.getSeconds()
    );

    const year = calendar.get('year');
    const month = calendar.get('month');
    const day = calendar.get('date');
    const hour = calendar.get('hour_of_day');
    const minute = calendar.get('minute');

    const isDST = calendar.get('dst_offset') !== 0;

    const formattedTime = `${year}-${month + 1}-${day} ${hour}:${minute}`;

    if (isDST) {
      return `${formattedTime} (夏令时)`;
    }

    return `${formattedTime} (标准时间)`;
  }
}

export { TimeZoneConverter, TimeZoneConversionResult, MultiTimeZoneTime };

const converter = new TimeZoneConverter();

const londonTime = new Date(2021, 2, 28, 10, 30, 0);
const conversion = converter.convertTimeBetweenZones(
  londonTime,
  'Europe/London',
  'America/New_York'
);
console.log(`伦敦时间 ${londonTime} 转换为纽约时间:`, conversion);

const currentTime = new Date();
const multiZoneTimes = converter.getTimeInMultipleZones(currentTime);
console.log(`当前时间在多个时区的表示:`);
multiZoneTimes.forEach(tz => {
  console.log(`  ${tz.timezone}: ${tz.localTime} (夏令时: ${tz.isDST})`);
});

const meetingTime = converter.findBestMeetingTime([
  'Europe/London',
  'America/New_York',
  'Asia/Shanghai'
]);
console.log(`推荐的会议时间:`, meetingTime);

const formattedTime = converter.formatTimeWithDSTIndicator(
  new Date(2021, 6, 15, 14, 30, 0),
  'Europe/London'
);
console.log(`格式化时间: ${formattedTime}`);