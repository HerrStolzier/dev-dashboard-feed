import Foundation

struct DailyDigestRenderer {
    func render(activity: GitRepoActivity, generatedAt: Date) -> String {
        let repo = activity.repo
        let dateText = DateFormatter.devboardDay.string(from: generatedAt)
        let commitCount = activity.commits.count
        let changedFileCount = activity.changedFileCount
        let topFiles = Array(Set(activity.commits.flatMap(\.changedFiles)).sorted().prefix(8))

        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escape(repo.name)) Daily Digest</title>
        <style>
        \(turboQuantStyle(accentColor: repo.accentColor))
        </style>
        </head>
        <body>
        <div class="container">
          <div class="header">
            <h1>\(escape(repo.name)) Daily Digest</h1>
            <p>Dein Projekt-Tagespost aus lokalen Git-Commits. Was heute passiert ist, welche Dateien bewegt wurden und welche Spur das Projekt gerade zieht.</p>
            <div class="badge-row">
              <span class="badge tech">Git Commits</span>
              <span class="badge hw">\(commitCount) Commit\(commitCount == 1 ? "" : "s")</span>
              <span class="badge status">\(changedFileCount) Datei\(changedFileCount == 1 ? "" : "en")</span>
              <span class="badge date">Stand: \(escape(dateText))</span>
            </div>
          </div>

          <div class="explainer">
            <div class="explainer-title">Was ist heute passiert?</div>
            <p><strong>\(escape(repo.name))</strong> hatte heute \(commitCount) sichtbare Git-Aktivität\(commitCount == 1 ? "" : "en"). Devboard hat daraus diesen lokalen Social-Post gebaut: kein Cloud-Call, keine API, nur dein Repo und ein bisschen Stil.</p>
          </div>

          <div class="phase verified">
            <div class="phase-header">
              <div class="phase-icon">✓</div>
              <div>
                <div class="phase-title">Heute bewegt</div>
                <div class="phase-subtitle">Commits seit dem letzten Devboard-Crawl</div>
              </div>
              <div class="phase-tag">Aktivität</div>
            </div>
            <div class="phase-goal">Das ist die chronologische Spur aus deinem Repo. Neueste Arbeit bleibt dadurch als schöner Projekt-Post sichtbar.</div>
            <div class="phase-body">
              <div class="info-list">
        \(activity.commits.map(renderCommit).joined(separator: "\n"))
              </div>
            </div>
          </div>

          <div class="matrix">
            <div class="matrix-title">Geänderte Dateien</div>
            <table>
              <thead>
                <tr>
                  <th>#</th>
                  <th>Pfad</th>
                  <th>Typ</th>
                </tr>
              </thead>
              <tbody>
        \(topFiles.enumerated().map(renderFileRow).joined(separator: "\n"))
              </tbody>
            </table>
          </div>

          <div class="recs">
            <div class="rec-card top-pick">
              <div class="rec-name">Nächster Blick</div>
              <div class="rec-desc">Öffne die wichtigsten Dateien aus diesem Digest, wenn du morgen wieder in \(escape(repo.name)) einsteigst.</div>
              <div class="rec-stats">Lokal erzeugt · \(escape(repo.path))</div>
              <div class="rec-tag recommended">Devboard Post</div>
            </div>
          </div>

          <div class="footer">Devboard Daily Digest · lokal generiert · \(escape(dateText))</div>
        </div>
        </body>
        </html>
        """
    }

    private func renderCommit(_ commit: GitCommitActivity) -> String {
        """
                <div class="info-item good"><span class="info-bullet"></span><strong>\(escape(commit.shortHash))</strong> — \(escape(commit.subject)) <span class="muted">von \(escape(commit.authorName)) · \(escape(DateFormatter.devboardTime.string(from: commit.authoredAt)))</span></div>
        """
    }

    private func renderFileRow(_ indexAndPath: EnumeratedSequence<[String]>.Element) -> String {
        let (index, path) = indexAndPath
        let type = URL(fileURLWithPath: path).pathExtension.isEmpty ? "Datei" : URL(fileURLWithPath: path).pathExtension.uppercased()
        return """
                <tr>
                  <td style="color:#71717a">\(index + 1)</td>
                  <td><span class="model-name qwen">\(escape(path))</span></td>
                  <td><span class="type-tag dense">\(escape(type))</span></td>
                </tr>
        """
    }

    private func turboQuantStyle(accentColor: String) -> String {
        """
          * { margin: 0; padding: 0; box-sizing: border-box; }

          body {
            font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #0a0a0f;
            color: #e4e4e7;
            min-height: 100vh;
            overflow-x: hidden;
          }

          body::before {
            content: '';
            position: fixed;
            top: -50%; left: -50%;
            width: 200%; height: 200%;
            background: radial-gradient(ellipse at 20% 30%, rgba(56, 189, 248, 0.07) 0%, transparent 50%),
                        radial-gradient(ellipse at 70% 20%, rgba(168, 85, 247, 0.06) 0%, transparent 50%),
                        radial-gradient(ellipse at 50% 80%, rgba(52, 211, 153, 0.05) 0%, transparent 50%);
            z-index: -1;
            animation: bgShift 20s ease-in-out infinite alternate;
          }

          @keyframes bgShift {
            0% { transform: translate(0, 0); }
            100% { transform: translate(-5%, -3%); }
          }

          .container { max-width: 1200px; margin: 0 auto; padding: 3rem 1.5rem 4rem; }
          .header { text-align: center; margin-bottom: 2rem; }
          .header h1 {
            font-size: 2.8rem; font-weight: 800;
            background: linear-gradient(135deg, #38bdf8, #a78bfa, #34d399);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;
            letter-spacing: -0.03em; margin-bottom: 0.75rem;
          }
          .header p { font-size: 1.05rem; color: #71717a; max-width: 750px; margin: 0 auto; line-height: 1.6; }
          .badge-row { display: flex; gap: 0.5rem; justify-content: center; margin-top: 1rem; flex-wrap: wrap; }
          .badge {
            display: inline-block; padding: 0.35rem 1rem; border-radius: 100px;
            font-size: 0.8rem; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase;
          }
          .badge.tech { background: rgba(56, 189, 248, 0.12); border: 1px solid rgba(56, 189, 248, 0.25); color: #7dd3fc; }
          .badge.status { background: rgba(251, 191, 36, 0.12); border: 1px solid rgba(251, 191, 36, 0.25); color: #fcd34d; }
          .badge.hw { background: rgba(168, 85, 247, 0.12); border: 1px solid rgba(168, 85, 247, 0.25); color: #c4b5fd; }
          .badge.date { background: rgba(52, 211, 153, 0.12); border: 1px solid rgba(52, 211, 153, 0.25); color: #6ee7b7; }
          .explainer, .phase, .matrix, .rec-card {
            background: rgba(24, 24, 32, 0.7); border: 1px solid rgba(63, 63, 70, 0.4);
            border-radius: 16px; backdrop-filter: blur(12px);
          }
          .explainer {
            margin: 2rem 0; background: rgba(56, 189, 248, 0.04); border-color: rgba(56, 189, 248, 0.15);
            padding: 1.75rem; position: relative; overflow: hidden;
          }
          .explainer::before, .phase::before {
            content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
            background: linear-gradient(90deg, #38bdf8, #a78bfa); opacity: 0.8;
          }
          .explainer-title { font-size: 1.1rem; font-weight: 800; color: #7dd3fc; margin-bottom: 0.75rem; }
          .explainer p { font-size: 0.88rem; color: #a1a1aa; line-height: 1.7; }
          .explainer strong { color: #e4e4e7; }
          .phase { margin: 2.5rem 0; overflow: hidden; position: relative; }
          .phase.verified::before { background: linear-gradient(90deg, #34d399, #6ee7b7); }
          .phase-header { padding: 1.5rem 1.75rem 1rem; display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; }
          .phase-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; background: rgba(52, 211, 153, 0.15); }
          .phase-title { font-size: 1.3rem; font-weight: 800; color: #f4f4f5; }
          .phase-subtitle { font-size: 0.88rem; color: #a1a1aa; margin-top: 2px; }
          .phase-tag { margin-left: auto; font-size: 0.75rem; font-weight: 600; padding: 0.3rem 0.8rem; border-radius: 100px; background: rgba(52, 211, 153, 0.12); color: #6ee7b7; }
          .phase-goal { padding: 0 1.75rem 1rem; font-size: 0.82rem; color: #71717a; line-height: 1.5; border-bottom: 1px solid rgba(63, 63, 70, 0.25); }
          .phase-body { padding: 0 1.75rem 1.5rem; }
          .info-list { display: flex; flex-direction: column; gap: 0.5rem; padding: 1.25rem 0 0; }
          .info-item { display: flex; align-items: baseline; gap: 0.65rem; padding: 0.4rem 0.6rem; border-radius: 6px; font-size: 0.85rem; color: #a1a1aa; line-height: 1.55; }
          .info-bullet { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; margin-top: 7px; background: \(accentColor); box-shadow: 0 0 6px \(accentColor); }
          .info-item.good { color: #6ee7b7; }
          .muted { color: #71717a; }
          .matrix { margin: 2rem auto; overflow: hidden; }
          .matrix-title { padding: 1.25rem 1.5rem 0.75rem; font-size: 0.8rem; font-weight: 700; color: #71717a; text-transform: uppercase; letter-spacing: 0.08em; }
          .matrix table { width: 100%; border-collapse: collapse; }
          .matrix th { padding: 0.6rem 1rem; text-align: left; font-size: 0.72rem; font-weight: 600; color: #52525b; text-transform: uppercase; letter-spacing: 0.06em; border-bottom: 1px solid rgba(63, 63, 70, 0.3); }
          .matrix td { padding: 0.7rem 1rem; font-size: 0.85rem; border-bottom: 1px solid rgba(63, 63, 70, 0.15); }
          .model-name { font-weight: 700; font-size: 0.88rem; font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace; }
          .model-name.qwen { color: #a78bfa; }
          .type-tag { font-size: 0.68rem; padding: 0.12rem 0.45rem; border-radius: 4px; font-weight: 600; white-space: nowrap; }
          .type-tag.dense { background: rgba(56, 189, 248, 0.12); color: #7dd3fc; }
          .recs { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 1rem; margin: 2rem 0; }
          .rec-card { padding: 1.25rem; transition: transform 0.2s ease, border-color 0.3s ease; }
          .rec-card.top-pick { border-color: rgba(52, 211, 153, 0.4); }
          .rec-name { font-family: 'SF Mono', monospace; font-size: 1rem; font-weight: 800; margin-bottom: 0.35rem; color: #6ee7b7; }
          .rec-desc { font-size: 0.82rem; color: #a1a1aa; line-height: 1.5; }
          .rec-stats { font-size: 0.78rem; color: #71717a; margin-top: 0.5rem; line-height: 1.5; }
          .rec-tag { display: inline-block; margin-top: 0.5rem; font-size: 0.68rem; font-weight: 600; padding: 0.15rem 0.5rem; border-radius: 100px; }
          .rec-tag.recommended { background: rgba(52, 211, 153, 0.12); color: #6ee7b7; }
          .footer { text-align: center; margin-top: 3rem; padding-top: 2rem; border-top: 1px solid rgba(63, 63, 70, 0.3); color: #52525b; font-size: 0.8rem; }
          @media (max-width: 720px) {
            .header h1 { font-size: 2rem; }
            .phase-header { flex-direction: column; align-items: flex-start; }
            .phase-tag { margin-left: 0; }
            .matrix { overflow-x: auto; }
          }
        """
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

extension DateFormatter {
    static let devboardDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let devboardTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
