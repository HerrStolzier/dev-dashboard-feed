import Foundation

struct DigestScheduler {
    let scheduledHour: Int

    init(scheduledHour: Int = 20) {
        self.scheduledHour = scheduledHour
    }

    func missedScheduledRun(lastSuccessfulRunAt: Date?, now: Date, calendar: Calendar = .current) -> Date? {
        guard let scheduledRun = mostRecentScheduledRun(before: now, calendar: calendar) else {
            return nil
        }

        if let lastSuccessfulRunAt, lastSuccessfulRunAt >= scheduledRun {
            return nil
        }

        return scheduledRun
    }

    func nextScheduledRun(after date: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let todayRun = calendar.date(byAdding: .hour, value: scheduledHour, to: startOfDay) ?? date

        if todayRun > date {
            return todayRun
        }

        return calendar.date(byAdding: .day, value: 1, to: todayRun) ?? date
    }

    private func mostRecentScheduledRun(before date: Date, calendar: Calendar) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)
        let todayRun = calendar.date(byAdding: .hour, value: scheduledHour, to: startOfDay)

        if let todayRun, todayRun <= date {
            return todayRun
        }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) else {
            return nil
        }

        return calendar.date(byAdding: .hour, value: scheduledHour, to: yesterday)
    }
}
