# Kong Bootcamp

Kong Gateway の学習・検証・運用のための包括的なリポジトリです。Kong Konnect (SaaS Control Plane) と Kubernetes 上の Data Plane を使用した実践的な環境構築、モニタリング、セキュリティスキャン、CI/CD 自動化を提供します。

## 📋 目次

- [概要](#概要)
- [主な機能](#主な機能)
- [ディレクトリ構造](#ディレクトリ構造)
- [前提条件](#前提条件)
- [クイックスタート](#クイックスタート)
- [GitHub Actions ワークフロー](#github-actions-ワークフロー)
- [モニタリング](#モニタリング)
- [Kong プラグイン](#kong-プラグイン)
- [テスト](#テスト)
- [ドキュメント](#ドキュメント)
- [トラブルシューティング](#トラブルシューティング)
- [貢献](#貢献)
- [ライセンス](#ライセンス)

---

## 概要

このリポジトリは、Kong Gateway の実践的な学習と運用を目的としています。以下の主要な機能を提供します：

- **Kong Konnect 統合**: SaaS Control Plane と Kubernetes Data Plane の連携
- **自動デプロイメント**: GitHub Actions による Data Plane の自動デプロイ
- **セキュリティスキャン**: Kong Gateway イメージの脆弱性スキャン (Trivy/Snyk)
- **モニタリング**: Prometheus と Grafana による Kong メトリクスの可視化
- **API 管理**: OpenAPI 仕様の管理と Konnect への自動デプロイ
- **テスト自動化**: API 負荷テストとモニタリングスクリプト

---

## 主な機能

### 🚀 自動デプロイメント
- Kong Data Plane を AKS (Azure Kubernetes Service) に自動デプロイ
- TLS 証明書の自動生成と Konnect への登録
- Kubernetes Secret の自動管理

### 🔒 セキュリティ
- Docker イメージの脆弱性スキャン (Trivy & Snyk)
- GitHub Container Registry (GHCR) への安全なイメージ公開
- GitHub Security タブでの脆弱性レポート

### 📊 モニタリング & 可視化
- Prometheus による Kong メトリクスの収集
- Grafana ダッシュボードでのリアルタイム可視化
- Kong Konnect 環境に最適化された PromQL クエリ

### 🔌 プラグイン管理
- Prometheus メトリクス

### 📝 API 仕様管理
- OpenAPI 3.0 仕様の管理
- Konnect Dev Portal への自動アップロード
- API ドキュメントの自動生成

---

## ディレクトリ構造

```
kong-bootcamp/
├── .github/
│   └── workflows/              # GitHub Actions ワークフロー
│       ├── deploy_dp.yaml      # Data Plane デプロイ
│       ├── deploy_oas.yaml     # OpenAPI 仕様デプロイ
│       ├── push-kong-gateway-image.yml  # イメージ公開
│       ├── scan-kong-gateway-image.yml  # セキュリティスキャン
│       ├── upload_doc.yaml     # ドキュメントアップロード
│       ├── upload_spec.yaml    # API 仕様アップロード
│       └── create_portal_api.yaml  # Portal API 作成
├── docs/
│   ├── openapi/                # OpenAPI 仕様ファイル
│   │   └── api-spec.yaml
│   └── product.md              # httpbin ホスティングガイド
├── kong-plugins/               # Kong プラグイン設定
│   └── gl-prometheus.yaml      # Prometheus プラグイン
├── monitoring/                 # モニタリング関連
│   ├── SETUP_GUIDE.md          # Prometheus/Grafana セットアップガイド
│   ├── SOLUTION.md             # トラブルシューティングと解決策
│   ├── kong-metrics.yaml       # Kong メトリクスサービス
│   ├── svcmon.yaml             # ServiceMonitor 設定
│   ├── check-kong-prometheus.ps1
│   ├── test-prometheus-metrics.ps1
│   ├── webhook-kong-route.yaml
│   └── webhook-server.yaml
├── tests/                      # テストスクリプト
│   ├── api_monitor.sh          # API モニタリングスクリプト
│   ├── load_test.sh            # 負荷テストスクリプト
│   ├── e2e.sh                  # E2E テスト (ダミー)
│   └── api_monitoring.log      # モニタリングログ
├── architecture-diagram.drawio # アーキテクチャ図
├── kong-gateway-architecture.drawio
└── README.md                   # このファイル
```

---

## 前提条件

### 必須ツール
- **Kubernetes クラスタ**: AKS (Azure Kubernetes Service) または他の Kubernetes 環境
- **kubectl**: Kubernetes CLI
- **Helm**: Kubernetes パッケージマネージャー
- **Azure CLI**: Azure リソース管理 (AKS を使用する場合)
- **Git**: バージョン管理

### Kong Konnect
- Kong Konnect アカウント
- Personal Access Token (PAT)
- Control Plane の作成

### GitHub
- GitHub アカウント
- GitHub Container Registry (GHCR) へのアクセス
- リポジトリ Secrets の設定

---

## クイックスタート

### 1. リポジトリのクローン

```bash
git clone https://github.com/API-PF/kong-bootcamp.git
cd kong-bootcamp
```

### 2. GitHub Secrets の設定

以下の Secrets を GitHub リポジトリに設定してください：

| Secret 名 | 説明 |
|-----------|------|
| `KONNECT_TOKEN` | Kong Konnect Personal Access Token |
| `AZURE_CREDENTIALS` | Azure Service Principal 認証情報 |
| `GITHUB_TOKEN` | GitHub Actions トークン (自動生成) |

### 3. GitHub Variables の設定

| Variable 名 | 説明 | 例 |
|-------------|------|-----|
| `KONNECT_REGION` | Konnect リージョン | `us` / `eu` / `au` |
| `CONTROL_PLANE` | Control Plane 名 | `my-control-plane` |
| `AKS_RESOURCE_GROUP_NAME` | AKS リソースグループ名 | `kong-rg` |
| `AKS_CLUSTER_NAME` | AKS クラスタ名 | `kong-aks` |
| `IMAGE_NAME` | コンテナイメージ名 | `kong-gateway` |
| `KONG_VER` | Kong バージョン | `3.8.0.0` |

### 4. Data Plane のデプロイ

GitHub UI から `Deploy Kong Data Plane` ワークフローを手動実行：

1. GitHub リポジトリの **Actions** タブを開く
2. **Deploy Kong Data Plane** を選択
3. **Run workflow** をクリック

---

## GitHub Actions ワークフロー

### 🚢 Deploy Kong Data Plane (`deploy_dp.yaml`)

**目的**: Kong Data Plane を Kubernetes クラスタにデプロイ

**トリガー**: 手動実行 (`workflow_dispatch`)

**主な処理**:
1. AKS への認証とクラスタ接続
2. TLS 証明書の生成と Konnect への登録
3. Kubernetes Secret の作成
4. Helm による Kong Data Plane のインストール

**使用方法**:
```bash
# GitHub Actions UI から実行
# または GitHub CLI を使用
gh workflow run deploy_dp.yaml
```

---

### 🔒 Push Kong Gateway Image to GHCR (`push-kong-gateway-image.yml`)

**目的**: DockerHub から Kong Gateway イメージを GHCR に公開

**トリガー**: 手動実行 (`workflow_dispatch`)

**主な処理**:
1. DockerHub から Kong Gateway イメージをプル
2. GHCR 用にタグ付け
3. GHCR にプッシュ

**使用方法**:
```bash
gh workflow run push-kong-gateway-image.yml
```

---

### 🔍 Scan Kong Gateway Image (`scan-kong-gateway-image.yml`)

**目的**: Kong Gateway イメージの脆弱性スキャン

**トリガー**:
- イメージ公開ワークフローの完了時 (自動)
- 手動実行 (`workflow_dispatch`)

**スキャンツール**:
- **Trivy**: 軽量で高速な脆弱性スキャナー
- **Snyk**: 詳細な脆弱性分析とモニタリング

**スキャン結果の確認**:
1. GitHub **Security** タブ → **Code scanning alerts**
2. ワークフロー実行の **Summary** タブ → **Artifacts** からレポートダウンロード

---

### 📋 Deploy OpenAPI Specification (`deploy_oas.yaml`)

**目的**: OpenAPI 仕様を Konnect に自動デプロイ

**トリガー**: 手動実行

**主な処理**:
1. OpenAPI 仕様ファイルの読み込み
2. Konnect API への POST
3. サービスとルートの自動生成

---

### 📚 Upload API Documentation (`upload_doc.yaml`, `upload_spec.yaml`)

**目的**: API ドキュメントと仕様を Konnect Dev Portal にアップロード

**トリガー**: 手動実行

**主な処理**:
1. ドキュメントファイルの読み込み
2. Konnect Dev Portal API への POST
3. Portal での公開設定

---

## モニタリング

### Prometheus と Grafana のセットアップ

詳細な手順は [`monitoring/SETUP_GUIDE.md`](monitoring/SETUP_GUIDE.md) を参照してください。

#### クイックセットアップ

```bash
# 1. Prometheus/Grafana スタックのインストール
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitor --create-namespace

# 2. Kong メトリクスサービスの作成
kubectl apply -f monitoring/kong-metrics.yaml

# 3. ServiceMonitor の適用
kubectl apply -f monitoring/svcmon.yaml

# 4. Grafana へアクセス
kubectl port-forward -n monitor svc/prometheus-grafana 3000:80

# デフォルト認証情報:
# ユーザー名: admin
# パスワード: prom-operator
```

### Grafana ダッシュボード設定

Kong Konnect 環境用の推奨 PromQL クエリ：

| パネル名 | PromQL クエリ |
|---------|-------------|
| 全体のリクエストレート | `sum(rate(kong_http_requests_total[5m]))` |
| サービス別リクエスト | `sum(rate(kong_http_requests_total[5m])) by (exported_service)` |
| ルート別リクエスト | `sum(rate(kong_http_requests_total[5m])) by (route)` |
| ステータスコード別 | `sum(rate(kong_http_requests_total[5m])) by (code)` |
| 成功率 (%) | `sum(rate(kong_http_requests_total{code=~"2.."}[5m])) / sum(rate(kong_http_requests_total[5m])) * 100` |
| レイテンシー P95 | `histogram_quantile(0.95, sum(rate(kong_latency_bucket[5m])) by (le, type))` |

詳細は [`monitoring/SOLUTION.md`](monitoring/SOLUTION.md) を参照してください。

---

## Kong プラグイン

### Prometheus プラグイン (`gl-prometheus.yaml`)

Kong メトリクスを Prometheus 形式で公開します。

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: prometheus
plugin: prometheus
```

---

## テスト

### API モニタリングスクリプト

```bash
# 1回のみ実行
./tests/api_monitor.sh

# 定期実行モード (60秒間隔)
./tests/api_monitor.sh --loop 60
```

### 負荷テストスクリプト

```bash
# 継続的な負荷テスト
./tests/load_test.sh
```

このスクリプトは以下のエンドポイントに対して継続的にリクエストを送信します：
- `/products` - 全製品リスト
- `/products/{id}` - 製品詳細
- `/products/{id}/reviews` - 製品レビュー
- `/products/{id}/ratings` - 製品評価

---

## ドキュメント

### httpbin コンテナホスティングガイド

[`docs/product.md`](docs/product.md) には、httpbin を使用した API テスト環境の構築方法が記載されています。

**httpbin とは**:
- HTTP リクエスト/レスポンスのモックサービス
- API テスト、プロトタイピング、学習に最適

**コンテナでの実行**:
```bash
docker run -d -p 8080:80 kennethreitz/httpbin
```

---

## トラブルシューティング

### よくある問題と解決策

#### 1. Grafana でメトリクスが表示されない

**原因**: 時間範囲が短すぎる、または PromQL クエリが不適切

**解決策**:
- 時間範囲を **Last 15 minutes** 以上に設定
- Kong Konnect 環境では `exported_service` ラベルを使用
- 詳細: [`monitoring/SOLUTION.md`](monitoring/SOLUTION.md)

#### 2. Data Plane が Control Plane に接続できない

**原因**: TLS 証明書の問題、または Konnect エンドポイントの誤り

**解決策**:
- TLS 証明書が正しく Konnect に登録されているか確認
- Control Plane エンドポイントの URL を確認
- Kubernetes Secret が正しく作成されているか確認

```bash
kubectl get secret kong-cluster-cert -n kong
```

#### 3. イメージスキャンで脆弱性が検出される

**対応**:
1. GitHub Security タブで詳細を確認
2. 脆弱性の重要度 (CRITICAL/HIGH/MEDIUM) を評価
3. Kong の最新バージョンにアップグレード
4. 必要に応じてパッチ適用

---

## 貢献

貢献を歓迎します！以下の手順に従ってください：

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

---

## ライセンス

このプロジェクトのライセンスについては、リポジトリ管理者にお問い合わせください。

---

## サポート

質問や問題がある場合は、GitHub Issues を作成してください。

---

## 参考リンク

- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Kong Gateway Documentation](https://docs.konghq.com/gateway/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
3. 「Artifacts」セクションで以下のファイルをダウンロード:
   - `trivy-scan-results` - Trivyによるスキャン結果（SARIF形式とテキスト形式）
   - `snyk-scan-results` - Snykによるスキャン結果（SARIF形式とテキスト形式、Snyk使用時のみ）

**注意**: 
- Snyk スキャンを使用するには、GitHub リポジトリの Secrets 設定で `SNYK_TOKEN` を設定する必要があります。Tokenが設定されていなくても、Trivyスキャンは実行されます。
- GitHub Advanced Security（有料機能）が有効な場合は、スキャン結果を「Security」タブの「Code scanning alerts」でも確認できます。
- ほとんどの場合、無料プランではAdvanced Securityは利用できないため、アーティファクトとして保存された結果を利用します。
