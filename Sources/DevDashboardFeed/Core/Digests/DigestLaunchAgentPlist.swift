import Foundation

struct DigestLaunchAgentPlist: Equatable {
    let label: String
    let executableURL: URL
    let standardOutURL: URL
    let standardErrorURL: URL
    let hour: Int
    let minute: Int

    init(
        label: String = DigestLaunchAgentInstaller.defaultLabel,
        executableURL: URL,
        standardOutURL: URL,
        standardErrorURL: URL,
        hour: Int = 20,
        minute: Int = 0
    ) {
        self.label = label
        self.executableURL = executableURL
        self.standardOutURL = standardOutURL
        self.standardErrorURL = standardErrorURL
        self.hour = hour
        self.minute = minute
    }

    var dictionary: [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [
                executableURL.path,
                "--run-digests-once",
                "--quiet",
            ],
            "StartCalendarInterval": [
                "Hour": hour,
                "Minute": minute,
            ],
            "StandardOutPath": standardOutURL.path,
            "StandardErrorPath": standardErrorURL.path,
            "EnvironmentVariables": [
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            ],
        ]
    }

    func data() throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: dictionary,
            format: .xml,
            options: 0
        )
    }
}
