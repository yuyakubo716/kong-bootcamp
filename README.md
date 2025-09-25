# Kong Gateway イメージスキャン

このリポジトリは、Kong Gateway の公式イメージをスキャンして脆弱性を検出することを目的としています。GitHub Actions を使用して DockerHub の Kong Gateway イメージを GitHub Container Registry (ghcr.io) にコピーし、そのイメージに対してセキュリティスキャンを実行します。

## ワークフロー概要

このリポジトリには2つの主要なワークフローが含まれています：

1. **Kong Gateway イメージの公開**
   - DockerHub から公式 Kong Gateway イメージをプルし、GHCR に再公開します
   - トリガー：
     - GitHub UI からの手動実行のみ

2. **セキュリティスキャンの実行**
   - GHCR に公開されたイメージの脆弱性スキャンを実行します
   - トリガー：
     - イメージ公開ワークフローの完了時
     - GitHub UI からの手動実行

## セキュリティスキャン

このリポジトリでは、以下のセキュリティスキャンツールを使用しています：

- **Trivy**: 軽量で使いやすいコンテナ脆弱性スキャナー
  - 主に既知の脆弱性（CVE）の検出に優れています
  - 重要度（CRITICAL, HIGH）によるフィルタリングを行います

- **Snyk**: より詳細な脆弱性分析と継続的なモニタリング
  - イメージ層の詳細分析と依存関係の調査
  - より広範囲なセキュリティデータベースとの照合

スキャン結果は GitHub Security タブで確認できます。

## 使用方法

### 方法1: 完全なプロセス
1. GitHub リポジトリの「Actions」タブを開く
2. 「Push Kong Gateway Image to GHCR」ワークフローを手動で実行
3. ワークフロー完了後、「Scan Kong Gateway Image」ワークフローが自動的に開始
4. ワークフロー完了後、「Summary」タブでスキャン結果のアーティファクトをダウンロード可能

### 方法2: 既存イメージのスキャンのみ
1. GitHub リポジトリの「Actions」タブを開く
2. 「Scan Kong Gateway Image」ワークフローを選択し「Run workflow」ボタンをクリック
3. ブランチを選択して「Run workflow」ボタンをクリック
4. ワークフロー完了後、「Summary」タブでスキャン結果のアーティファクトをダウンロード可能

### スキャン結果の確認方法
1. ワークフロー実行の詳細ページを開く
2. 「Summary」タブに移動
3. 「Artifacts」セクションで以下のファイルをダウンロード:
   - `trivy-scan-results` - Trivyによるスキャン結果（SARIF形式とテキスト形式）
   - `snyk-scan-results` - Snykによるスキャン結果（SARIF形式とテキスト形式、Snyk使用時のみ）

**注意**: 
- Snyk スキャンを使用するには、GitHub リポジトリの Secrets 設定で `SNYK_TOKEN` を設定する必要があります。Tokenが設定されていなくても、Trivyスキャンは実行されます。
- GitHub Advanced Security（有料機能）が有効な場合は、スキャン結果を「Security」タブの「Code scanning alerts」でも確認できます。
- ほとんどの場合、無料プランではAdvanced Securityは利用できないため、アーティファクトとして保存された結果を利用します。
