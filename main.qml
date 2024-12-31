import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore

import org.qfield
import org.qgis
import Theme


Item {
  id: plugin
  
  Settings {
    id: settings
    property string api_url: "https://api.openai.com/v1/chat/completions"
    property string api_model: "gpt-4o"
    property string api_key
    property string prompt_prefix: "List interesting tourist attractions near"
    
  }

  property var mainWindow: iface.mainWindow()
  property var positionSource: iface.findItemByObjectName('positionSource')

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }
  
  QfToolButton {
    id: pluginButton
    iconSource: 'icon.svg'
    iconColor: Theme.mainColor
    bgcolor: Theme.darkGray
    round: true
    
    onClicked: {
      fetchAnswer()
    }
    onPressAndHold: {
            optionDialog.open()
        }
  }

  function fetchAnswer() {

    let position = positionSource.positionInformation
    if (positionSource.active && position.latitudeValid && position.longitudeValid) {
      mainWindow.displayToast(qsTr('Your current position is ' + position.latitude + ', ' +position.longitude))
    } else {
      mainWindow.displayToast(qsTr('Your current position is unknown\n Not loading POIs nearby'))
      return;
    }
    
    console.log('Fetching results....');

    let prompt = `${settings.prompt_prefix} latitude ${position.latitude} and longitude ${position.longitude}.`;
    console.log(prompt);  

    let requestData = {
      model: settings.api_model,
      messages: [
          { role: "developer", content: "You should always return valid geojson only" },
          {
              role: "user", content: prompt,
          },
      ],
      response_format: {
          // could also use /docs/guides/structured-outputs
          type: "json_object",
          }
      }


    let request = new XMLHttpRequest();
    
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        console.log(request.response)
        
        var response = JSON.parse(request.response)
        if (response.choices && response.choices.length > 0) {
          let content = JSON.stringify(response.choices[0]['message']['content'])
          mainWindow.displayToast(content)
          //console.log(content)
        
        } else {
          mainWindow.displayToast("No response from API")
        }
      }
    }
    //let viewbox = GeometryUtils.reprojectRectangle(context.targetExtent, context.targetExtentCrs, CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"])).toString().replace(" : ", ",")
    request.open("POST", settings.api_url, true);
    request.setRequestHeader("Authorization", `Bearer ${settings.api_key}`);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.stringify(requestData));
  }
    Dialog {
        id: optionDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("AI settings")

        width: mainWindow.width * 0.8
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        ColumnLayout {
            width: parent.width
            spacing: 10
            Label {
                id: labelApiUrl
                Layout.fillWidth: true
                text: qsTr("API URL")
            }

            QfTextField {
                id: textFieldApiUrl
                Layout.fillWidth: true
                text: settings.api_url
            }
            Label {
                id: labelApiKey
                Layout.fillWidth: true
                text: qsTr("API key")
            }

            QfTextField {
                id: textFieldApiKey
                Layout.fillWidth: true
                text: settings.api_key
            }
            Label {
                id: labelApiModel
                Layout.fillWidth: true
                text: qsTr("API Model")
            }

            QfTextField {
                id: textFieldApiModel
                Layout.fillWidth: true
                text: settings.api_model
            }

            Label {
                id: labelPrompPrefix
                Layout.fillWidth: true
                text: qsTr("Prompt prefix (current Lat/Lon will be added automatically)")
            }

            QfTextField {
                id: textFieldPromptPrefix
                Layout.fillWidth: true
                text: settings.prompt_prefix
            }
            
        }

        onAccepted: {
            settings.api_key = textFieldApiKey.text;
            settings.api_url = textFieldApiUrl.text;
            settings.prompt_prefix = textFieldPromptPrefix.text;
            mainWindow.displayToast(qsTr("Settings stored"));
        }
    }
}