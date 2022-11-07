<img width="220" alt="appicon" src="https://user-images.githubusercontent.com/20147818/200149330-aac5fa0c-ae0a-41ee-9f76-229ea9c0c885.png" align="left"/>
<div>
<h2>Walkly - 歩数計アプリ</h2>
<p>iPhone向けの歩数計アプリです。Appleヘルスケアの計測データを使用して歩数を表示します。歩数から換算した移動距離や消費カロリーも表示できます。<br>
ホーム画面やロック画面に追加できるウィジェットにも対応しています。</p>

<a href="https://apps.apple.com/jp/app/walkly-%E6%AD%A9%E6%95%B0%E8%A8%88%E3%82%A2%E3%83%97%E3%83%AA/id6444238144" target="_blank"><img src="https://user-images.githubusercontent.com/20147818/200310005-664e3ddb-761e-48c9-a1cb-06af037804a9.svg"/></a>

</div>
<br/>

## スクリーンショット
![image](https://user-images.githubusercontent.com/20147818/200150422-f1bd9269-f07f-4f2d-956c-5be220baf425.png)

<div align="center">

</div>

## アプリのダウンロード
iPhoneでApp Storeにアクセスしてダウンロードしてください。

[![Download_on_the_App_Store_Badge_JP_RGB_blk_100317](https://user-images.githubusercontent.com/20147818/200310005-664e3ddb-761e-48c9-a1cb-06af037804a9.svg)](https://apps.apple.com/jp/app/walkly-%E6%AD%A9%E6%95%B0%E8%A8%88%E3%82%A2%E3%83%97%E3%83%AA/id6444238144)

## 主な機能
Appleヘルスケアの計測データをリアルタイムに取得することで歩数や関連する情報を表示します。Apple Watchを併用している場合はiPhoneとApple Watchの歩数カウントを重複なしでマージして表示します。
- 歩数
- 移動距離・消費カロリー・エクササイズ時間の表示(歩数からの換算値)
- 歩数グラフ - 1時間毎、日毎
- ウィジェット表示（ホーム画面、ロック画面）

### 使用できるウィジェットの形状

| 配置場所  | ウィジェットの形状                  |
| -------- | ----------------------------- |
| ホーム画面 | Small, Medium                 |
| ロック画面  | Circular, Rectangular, Inline |

> **Warning**
> ウィジェットの表示間隔はiOSの仕様上バッテリーの消費を抑制するために5〜15分程度の表示ラグが発生します。すぐに更新したい場合は、ウィジェットをタップしてアプリを起動することで最新に更新されます。

> **Warning**
> Appleヘルスケアの値は端末がロックされていると暗号化されているため読み取ることができません。読み取りに失敗した場合は警告アイコンが表示されますので、ウィジェットをタップすると最新の値を読み取ります。
> 
> ![image](https://user-images.githubusercontent.com/20147818/200151181-2b4702e8-dc35-48dd-a35c-99412f652ea9.png)

## 動作環境
- iOS 16 が動作するiPhoneで動作します。iOS 16.1で動作確認済みです。 <br>
iOS 16 よりサポートされたChartやホーム画面のウィジェットAPIを使用しているため、iOS 16より前のバージョンにはインストールできません。

## サポート言語
- 日本語
- English

# プライバシーポリシー
- 利用者情報の取得<br>
本アプリはヘルスケアデータから歩数情報を取得します。アプリの起動時に取得を許可するかの問い合わせ画面が表示されますので各項目の読み出しを許可してください。以下の項目以外のヘルスケアデータ、および個人情報を取得することはありません。<br>
  ・歩数<br>
  ・アクティブエネルギー<br>
  ・ウォーキングデッド＋ランニング距離<br>
  ・エクササイズ時間<br>
- 利用者情報の利用<br>
  本アプリが利用者の個人情報を利用することはありません。
- 利用者情報の第三者提供<br>
  本アプリが利用者の個人情報を第三者へ提供することはありません。
- お問い合わせ先<br>
  下記のお問い合わせフォームをご利用ください。

# お問い合わせ先
アプリに関するご質問はお問い合わせフォームをご利用ください。Googleへのログインは不要です。
- [お問い合わせフォーム(アプリ利用者向け)](https://docs.google.com/forms/d/e/1FAIpQLScioz3HhixRDN5C5QQD6BqlHFQHY4wTTYkn6mJ8Z6AUA8LTtg/viewform?vc=0&c=0&w=1&flr=0)

> **Note**
> 開発者の方からのご質問はGitHubのコミュニケーション機能をご利用ください。

## 開発者向け情報

### ビルドツール
- Xcode 14.1

### ビルドの手順
1. XcodeでWalkly.xcodeprojを開きます。
2. Xcodeのメニューから Product > Build でビルドします。
