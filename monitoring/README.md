# Prometheus + Grafana for Kong on AKS

このディレクトリには、AKS (Azure Kubernetes Service) 上で稼働するKong Data Planeを監視するための、Prometheus と Grafana の構築マニフェストファイルが含まれています。

## アーキテクチャ概要

- **Prometheus**: Kongメトリクスを収集する監視システム
- **Grafana**: Prometheusのメトリクスを可視化するダッシュボード

## 前提条件

1. AKSクラスターが作成済みであること
2. `kubectl` がインストール済みで、AKSクラスターに接続できること
3. **Kong Data Planeが既にデプロイ済みであること**
   - GitHub Actions ワークフロー (`.github/workflows/deploy_dp.yaml`) でデプロイされている必要があります
   - Kong は `kong` namespace にデプロイされていることを想定しています

## デプロイ手順

### 前提: Kong Data Planeのデプロイ

Kong Data Planeは GitHub Actions ワークフロー (`.github/workflows/deploy_dp.yaml`) で既にデプロイされている必要があります。

Kong の状態を確認:
```bash
kubectl get pods -n kong
kubectl get svc -n kong
```

### 1. Monitoring Namespace の作成

```bash
kubectl apply -f 01-namespace.yaml
```

### 2. Prometheus のデプロイ

PrometheusはKong namespace内のServiceを自動検出してメトリクスを収集します。

```bash
kubectl apply -f 02-prometheus-config.yaml
kubectl apply -f 03-prometheus-deployment.yaml
kubectl apply -f 04-prometheus-service.yaml
```

### 3. Grafana のデプロイ

```bash
kubectl apply -f 05-grafana-config.yaml
kubectl apply -f 06-grafana-deployment.yaml
kubectl apply -f 07-grafana-service.yaml
```

### 4. (オプション) Kong メトリクスへの外部アクセス設定

インターネットからKong Data Planeの `/metrics` エンドポイントにアクセスして構築確認を行う場合、以下のいずれかの方法を選択してください。

#### 方法A: LoadBalancerを使用（簡単・推奨）

```bash
kubectl apply -f 09-kong-metrics-service-external.yaml
```

外部IPアドレスの取得:
```bash
kubectl get svc kong-metrics-external -n kong
```

アクセス方法:
```bash
# 外部IPアドレスが割り当てられたら
curl https://<EXTERNAL-IP>:8444/metrics -k

# または
curl http://<EXTERNAL-IP>:8001/metrics
```

#### 方法B: Ingressを使用（本番環境推奨）

前提: NGINX Ingress ControllerまたはAzure Application Gatewayが設定済みであること

1. `08-kong-metrics-ingress.yaml` を編集してドメイン名を設定:
```yaml
spec:
  rules:
  - host: kong-metrics.example.com  # 実際のドメイン名に変更
```

2. Ingressをデプロイ:
```bash
kubectl apply -f 08-kong-metrics-ingress.yaml
```

3. アクセス確認:
```bash
curl http://kong-metrics.example.com/metrics
```

**セキュリティ注意事項:**
- 本番環境では必ずBasic認証またはIPホワイトリストを設定してください
- TLS/HTTPSの使用を強く推奨します
- `/metrics` エンドポイントには機密情報が含まれる可能性があります

### 5. デプロイ状態の確認

```bash
# Monitoring namespaceのリソースを確認
kubectl get all -n monitoring

# Podの状態を確認
kubectl get pods -n monitoring

# Kong namespaceの確認
kubectl get pods -n kong
kubectl get svc -n kong
kubectl get ingress -n kong  # Ingressを設定した場合
```

### 6. メトリクスアクセスのテスト

デプロイ後、自動テストスクリプトで各アクセス方法を確認できます:

```bash
# Linux/Mac
./test-metrics-access.sh

# Windows PowerShell
.\test-metrics-access.ps1
```

このスクリプトは以下をテストします:
- Kong Pod内部からのアクセス
- LoadBalancer経由の外部アクセス（設定している場合）
- Ingress経由の外部アクセス（設定している場合）

## アクセス方法

### Kong メトリクスの確認

#### 方法1: Port Forward（開発環境・内部確認用）

Kong Data PlaneのAdmin APIからメトリクスを確認できます:

```bash
# Kong Podにポートフォワード
kubectl port-forward -n kong $(kubectl get pod -n kong -l app.kubernetes.io/name=kong -o name | head -1) 8001:8001
```

メトリクスの確認:
```bash
curl http://localhost:8001/metrics
```

#### 方法2: LoadBalancer経由（外部アクセス）

`09-kong-metrics-service-external.yaml` をデプロイした場合:

```bash
# 外部IPアドレスを取得
EXTERNAL_IP=$(kubectl get svc kong-metrics-external -n kong -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "External IP: $EXTERNAL_IP"

# メトリクスにアクセス
curl https://$EXTERNAL_IP:8444/metrics -k
# または
curl http://$EXTERNAL_IP:8001/metrics
```

#### 方法3: Ingress経由（本番環境推奨）

`08-kong-metrics-ingress.yaml` をデプロイした場合:

```bash
# ドメイン名経由でアクセス
curl http://kong-metrics.example.com/metrics

# Basic認証が設定されている場合
curl -u admin:password http://kong-metrics.example.com/metrics
```

**注意:** ServiceMonitorが有効な場合、PrometheusがKong Podから自動的にメトリクスを収集します

### Prometheus (Port Forward)

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

- Prometheus UI: http://localhost:9090

### Grafana (Port Forward)

```bash
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

- Grafana UI: http://localhost:3000
- デフォルト認証情報:
  - ユーザー名: `admin`
  - パスワード: `admin` (初回ログイン後に変更を推奨)

## Grafana の設定

### 1. Prometheusデータソースの追加

ConfigMapで既に設定済みのため、Prometheusデータソースは自動的に追加されます。

Grafana UIで確認する場合:
1. Configuration > Data Sources
2. Prometheus が登録されていることを確認
3. URL: `http://prometheus.monitoring.svc.cluster.local:9090`

### 2. Kong ダッシュボードの確認

ConfigMapで既にダッシュボードが設定されているため、以下の手順で確認できます:

1. Grafana UIにログイン
2. Dashboards > Browse
3. "Kong Gateway" フォルダ内に "Kong Gateway Dashboard" が自動的に作成されています

追加のダッシュボードをインポートする場合:
- Grafana.com Dashboard ID: `7424` (Kong Official Dashboard)

## Kong Prometheus Pluginの確認

Kong Data PlaneでPrometheusメトリクスが公開されているか確認してください:

### メトリクスエンドポイントの確認

```bash
# Kong Podにポートフォワード
kubectl port-forward -n kong $(kubectl get pod -n kong -l app.kubernetes.io/name=kong -o name | head -1) 8001:8001

# メトリクスの確認
curl http://localhost:8001/metrics
```

Kong Konnectで既にPrometheusプラグインが有効化されている、またはHelm values.yamlで `serviceMonitor.enabled: true` が設定されている場合、メトリクスは自動的に公開されます。

### Kong Konnect UIでプラグイン確認

1. Kong Konnect にログイン
2. 対象の Control Plane を選択
3. Gateway Services > Plugins で Prometheus プラグインが有効か確認

## トラブルシューティング

### Kong Data Planeの状態確認

Kong Data Planeは GitHub Actions でデプロイされています。問題がある場合:

```bash
# Kong Podの状態確認
kubectl get pods -n kong
kubectl describe pods -n kong -l app.kubernetes.io/name=kong

# Kong Podのログ確認
kubectl logs -n kong -l app.kubernetes.io/name=kong
```

### Prometheusがメトリクスを収集できない場合

```bash
# Prometheusのターゲット状態を確認
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# ブラウザで http://localhost:9090/targets にアクセス

# Kong Admin APIのメトリクスエンドポイントを確認
kubectl port-forward -n kong $(kubectl get pod -n kong -l app.kubernetes.io/name=kong -o name | head -1) 8001:8001
curl http://localhost:8001/metrics
```

**ServiceMonitorの確認:**
GitHub Actionsのdeploy_dp.yamlで `serviceMonitor.enabled: true` が設定されているか確認してください。

### Grafanaにダッシュボードが表示されない場合

1. Prometheusデータソースが正しく設定されているか確認
2. Prometheusでメトリクスが収集されているか確認 (Explore > Prometheus)
3. Kong Data PlaneでPrometheusメトリクスが公開されているか確認
4. GitHub Actionsのvalues.yamlで `serviceMonitor.enabled: true` が設定されているか確認

### 外部から /metrics にアクセスできない場合

**LoadBalancerを使用している場合:**
```bash
# Serviceの状態確認
kubectl get svc kong-metrics-external -n kong

# EXTERNAL-IPが<pending>の場合は待つ
kubectl describe svc kong-metrics-external -n kong

# AKSの場合、LoadBalancerが正しくプロビジョニングされているか確認
az network lb list --resource-group <MC_リソースグループ名>
```

**Ingressを使用している場合:**
```bash
# Ingressの状態確認
kubectl get ingress kong-metrics-ingress -n kong
kubectl describe ingress kong-metrics-ingress -n kong

# Ingress Controllerのログ確認
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx-controller

# DNSの名前解決確認
nslookup kong-metrics.example.com
```

**共通の確認事項:**
```bash
# Kong Podが正常に動作しているか
kubectl get pods -n kong -l app.kubernetes.io/name=kong
kubectl logs -n kong -l app.kubernetes.io/name=kong

# Kong Admin APIが応答するか（Pod内から）
kubectl exec -n kong <kong-pod-name> -- curl -s http://localhost:8001/metrics
```

**ネットワークセキュリティの確認:**
- Azure NSG (Network Security Group) でポートが開いているか確認
- LoadBalancerのソースIP制限が正しく設定されているか確認
- ファイアウォールルールでアクセスがブロックされていないか確認

## 本番環境への考慮事項

### セキュリティ

- [ ] Grafanaのデフォルトパスワードを変更
- [ ] NetworkPolicyを設定してPod間通信を制限
- [ ] IngressまたはAzure Application Gatewayを使用した外部アクセス制御
- [ ] Grafana用のAzure ADまたはOAuth認証を設定
- [ ] Kong メトリクスエンドポイントへのアクセス制御（Basic認証、IPホワイトリスト）
- [ ] TLS/HTTPSの使用（Let's EncryptまたはAzure証明書）
- [ ] LoadBalancerのソースIP制限 (`loadBalancerSourceRanges`)
- [ ] Kong Admin APIへの外部アクセスは最小限に（VPN経由推奨）

### スケーラビリティ

- [ ] Prometheusの永続ボリューム設定 (現在はemptyDirを使用)
- [ ] Grafanaの永続ボリューム設定
- [ ] PrometheusのリソースリクエストとリミットをWorkloadに合わせて調整

### 監視とロギング

- [ ] Azure Monitorとの統合
- [ ] アラートルールの設定 (PrometheusのAlertmanagerまたはAzure Monitor)
- [ ] ログ収集 (Fluent Bit / Azure Log Analyticsなど)

## クリーンアップ

監視スタック（Prometheus + Grafana）のみを削除する場合:

```bash
# 外部アクセス設定を削除（設定した場合）
kubectl delete -f 09-kong-metrics-service-external.yaml --ignore-not-found=true
kubectl delete -f 08-kong-metrics-ingress.yaml --ignore-not-found=true

# すべての監視リソースを削除
kubectl delete -f 07-grafana-service.yaml
kubectl delete -f 06-grafana-deployment.yaml
kubectl delete -f 05-grafana-config.yaml
kubectl delete -f 04-prometheus-service.yaml
kubectl delete -f 03-prometheus-deployment.yaml
kubectl delete -f 02-prometheus-config.yaml
kubectl delete -f 01-namespace.yaml
```

または、クリーンアップスクリプトを使用:
```bash
# Linux/Mac
./cleanup.sh

# Windows PowerShell
.\cleanup.ps1
```

**注意:** Kong Data Planeは削除されません。Kong Data Planeを削除する場合は、別途Helmコマンドで削除してください:
```bash
helm uninstall kong-iac -n kong
```

## 参考リンク

- [Kong Konnect Documentation](https://docs.konghq.com/konnect/)
- [Kong Gateway in Kubernetes](https://docs.konghq.com/gateway/latest/install/kubernetes/)
- [Kong Prometheus Plugin](https://docs.konghq.com/hub/kong-inc/prometheus/)
- [Kong Admin API - /metrics](https://docs.konghq.com/gateway/latest/reference/metrics/)
- [Prometheus Kubernetes Deployment](https://prometheus.io/docs/prometheus/latest/installation/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)

## ファイル一覧

```
monitoring/
├── 01-namespace.yaml                      # monitoring namespace
├── 02-prometheus-config.yaml              # Prometheus設定
├── 03-prometheus-deployment.yaml          # Prometheus Deployment + RBAC
├── 04-prometheus-service.yaml             # Prometheus Service
├── 05-grafana-config.yaml                 # Grafana設定 + ダッシュボード
├── 06-grafana-deployment.yaml             # Grafana Deployment
├── 07-grafana-service.yaml                # Grafana Service
├── 08-kong-metrics-ingress.yaml           # Kong メトリクス用Ingress (オプション)
├── 09-kong-metrics-service-external.yaml  # Kong メトリクス用LoadBalancer (オプション)
├── deploy.sh                              # Bashデプロイスクリプト
├── deploy.ps1                             # PowerShellデプロイスクリプト
├── cleanup.sh                             # Bashクリーンアップスクリプト
├── cleanup.ps1                            # PowerShellクリーンアップスクリプト
├── test-metrics-access.sh                 # Bashメトリクスアクセステストスクリプト
├── test-metrics-access.ps1                # PowerShellメトリクスアクセステストスクリプト
└── README.md                              # このファイル
```
