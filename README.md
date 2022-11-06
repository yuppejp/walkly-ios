<img width="220" alt="appicon" src="https://user-images.githubusercontent.com/20147818/200149330-aac5fa0c-ae0a-41ee-9f76-229ea9c0c885.png" align="left"/>
<div>
<h2>Walkly - iPhone版</h2>
<p>iPhone向けの歩数計アプリです。Appleヘルスケアの計測データを使用して歩数を表示します。歩数から換算した移動距離や消費カロリーも表示できます。</p>
<p>ホーム画面やロック画面に追加できるウィジェットにも対応しています。注：端末がロックされている場合はヘルスデータが暗号化されてアクセスできないため前回の計測値を表示します。</p>
</div>
<br/>

## スクリーンショット
![image](https://user-images.githubusercontent.com/20147818/200150422-f1bd9269-f07f-4f2d-956c-5be220baf425.png)

<div align="center">

</div>

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
  本アプリが利用者の個人情報を取得することはありません。
- 利用者情報の利用<br>
  本アプリが利用者の個人情報を利用することはありません。
- 利用者情報の第三者提供<br>
  本アプリが利用者の個人情報を第三者へ提供することはありません。
- お問い合わせ先<br>
  下記のお問い合わせフォームをご利用ください。

# お問い合わせフォーム
https://docs.google.com/forms/d/e/1FAIpQLScioz3HhixRDN5C5QQD6BqlHFQHY4wTTYkn6mJ8Z6AUA8LTtg/viewform?vc=0&c=0&w=1&flr=0

  何かご不明な点がございましたら上記のお問い合わせフォームをご利用ください。
## 開発者向け情報

### ビルドツール
- Xcode 14.1

### ビルドの手順
1. XcodeでWalkly.xcodeprojを開きます。
2. Xcodeのメニューから Product > Build でビルドします。
