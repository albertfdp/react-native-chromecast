import React from 'react-native';

const {
  Text,
  View,
  StyleSheet,
  TouchableHighlight,
  DeviceEventEmitter
} = React;
const { ChromecastManager } = React.NativeModules;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  }
});


export default class GoogleChromeCastIOS extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      isScanning: false,
      devices: []
    };
  }

  componentDidMount() {
    DeviceEventEmitter.addListener('GoogleChromecast:DeviceListChanged', this.handleDeviceListChanged.bind(this));
  }

  componentWillUnmount() {
    if (this.state.isScanning) {
      this.setState({ isScanning: false}, () => ChromecastManager.stopScan);
    }
    ChromecastManager.disconnect();
  }

  handleDeviceListChanged(data) {
    console.log('handleDeviceListChanged', data);
    this.setState({ devices: data.devices });
  }

  handleStartScan() {
    this.setState({ isScanning: true }, () => {
      ChromecastManager.startScan();
    });
  }

  handleConnectToDevice(deviceName) {
    this.setState({ isConnected: true }, () => {
      ChromecastManager.connectToDevice(deviceName);
      this.startObservingStreamPosition();
    });
  }

  startObservingStreamPosition() {
    let self = this;
    this.stopObserviceStreamPosition();
    this.setState({ position: setInterval(() => {
      ChromecastManager.getStreamPosition(pos => {
        console.log(pos);
        self.setState({ currentPosition: pos });
      });
    })});
  }

  stopObserviceStreamPosition() {
    if (this.state.position != null) {
      clearInterval(this.state.position);
      this.setState({ position: null })
    }
  }

  renderDevices() {
    if (this.state.devices.length === 0) {
      return null;
    }
    return (
      <View>
        {this.state.devices.map((device, idx) => {
          console.log(device);
          return (
            <TouchableHighlight key={idx} onPress={() => this.handleConnectToDevice(device)}>
              <Text>{device}</Text>
            </TouchableHighlight>
          );
        })}
      </View>
    );
  }

  cast() {
    ChromecastManager.castVideo(
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'React Native Chromecast',
      'Casting from an iOS app running on JavaScript',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'
    );
  }

  renderCast() {
    return (
      <TouchableHighlight onPress={() => this.cast()}>
        <Text>Cast</Text>
      </TouchableHighlight>
    );
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Google Chromecast
        </Text>
        <TouchableHighlight onPress={this.handleStartScan.bind(this)}>
          <Text>{this.state.isScanning ? 'Scanning ...' : 'Scan devices'}</Text>
        </TouchableHighlight>

        {this.renderDevices()}
        {this.state.isConnected ? this.renderCast() : null}

      </View>
    );
  }
}
