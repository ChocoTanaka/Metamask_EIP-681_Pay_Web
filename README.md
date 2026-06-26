# MetaMask JPYC Sub-Payment System (Web版)

MetaMaskから**JPYCをQRコード読み取りで簡単に支払い**できるサブアプリのWeb版です。

請求書の明細・但し書き・税区分などの**追加書類に強い**請求書特化型ツールとして作っています。

---

## すぐに試す
- **Web版** → [ここから使う](https://chocotanaka.github.io/Metamask_EIP-681_Pay_Web/)
- **Androidアプリ版** → [Google Play](https://play.google.com/store/apps/details?id=com.tanakasenki.eip681pay&hl=ja)

## 主な特徴
- ERC-681準拠のQR決済対応
- MetaMask（またはBase Wallet推奨）でスムーズに支払い
- ノンカストディ（直接送金）

---

## 使い方（接続）
1. Web版を開く
2. コネクトボタンを押す

<img src="https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay_Web/master/assets/images/screenshot_intro.png" alt="〇を押してね" title="〇を押してね">

3. 所定のウォレットを選択する（スマホなら所定のアプリに移動します）

<img src="https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay_Web/master/assets/images/screenshot_connect.png" alt="自由選択" title="自由選択">

4. ボタンが青くなったら完了。青くなってないなら、もう一回押して接続を確認しよう。

##  使い方（書き出し）

1. 確認用に16桁のタグ、宛名、金額、振込先の名前（つまり自分の名前）を書き、SETを押す。
2. 確認後、「PDFを発行する」を押す

<img src="https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay_Web/master/assets/images/testpdf1.png" alt="支払用紙" title="支払用紙">

3. このPDFを請求書とともに送る

## 使い方（読み取り）

1. 請求書やERC-681準拠の二次元バーコードを読み取り
2. 金額・明細を確認して、OKを押す。

詳細な説明・スクリーンショットは[SubPayment解説.pdf](https://github.com/ChocoTanaka/Metamask_EIP-681_Pay_Web/blob/master/SubPayment%E8%A7%A3%E8%AA%AC.pdf)を参照してください。

## 注意
- Polygonネットワーク推奨（ガス代はPOLなどで別途必要）
- JPYCの実用決済ツールとして、振込に近い形で使えるよう設計しています

---

## プライバシーポリシー
- このwebページはユーザーから情報を収集することはありません。
- 作成した書類の正誤に関しては、技術的な問題であることが判明したときのみ対応いたします。

---
**フィードバック・要望大歓迎です！**  
IssueやX（@SENKI_MMSub）までお願いします。
