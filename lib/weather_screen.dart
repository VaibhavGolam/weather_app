import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/additiona_info_item.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late TextEditingController textEditingController;
  late String cityName; // Declare cityName variable

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    cityName = 'Goa'; // Set default city name
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // String cityName = 'Goa';
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey'),
      );

      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw 'an unexpected error occurred! \n try refreshing!';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //upper Appbar
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          //refresh button
          IconButton(
              onPressed: () async {
                setState(() {
                  // Reset cityName to 'Goa' before refresh
                  cityName = 'Goa';
                });

                // Perform the refresh action
                try {
                  await getCurrentWeather();
                } catch (e) {
                  // Handle the error (city not found)
                  debugPrint(
                      'Error: City not found. Setting to default city (Goa)');
                  setState(
                    () {
                      cityName = 'Goa';
                    },
                  );
                }
              },
              icon: const Icon(Icons.refresh)),
          // IconButton(onPressed: () {}, icon: const Icon(Icons.dark_mode))
        ],
      ),

      //center body
      body: FutureBuilder(
        future: getCurrentWeather(),
        builder: (context, snapshot) {
          print(snapshot);
          print(snapshot.runtimeType);

          //if async is loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          // if async has error
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          //current data
          final tempKelvin =
              currentWeatherData['main']['temp'] as double; //in kelvin
          final currentTemp =
              tempKelvin - 273.15; //converted to celcius (still  double)

          final currentSky = currentWeatherData['weather'][0]['main'];
          final int currentHumidity = currentWeatherData['main']['humidity'];
          final int currentPressure = currentWeatherData['main']['pressure'];
          final double currentWindspeed = currentWeatherData['wind']['speed'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Main card
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    '${currentTemp.toStringAsFixed(2)} °C',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Icon(
                                    currentSky == 'Clouds' ||
                                            currentSky == 'Rain'
                                        ? Icons.cloud
                                        : Icons.sunny,
                                    size: 60,
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    currentSky,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Text(
                                    cityName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //gap between cards
                    const SizedBox(
                      height: 20,
                    ),

                    //weather forecast heading
                    const Text(
                      'Weather forecast',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    // weather forecast horzontal cards
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(5, (i) {
                          final tempKelvin = data['list'][i + 1]['main']['temp']
                              as double; // Temperature in Kelvin
                          final tempCelsius =
                              tempKelvin - 273.15; // Convert Kelvin to Celsius
                          final temperatureCelsiusString =
                              '${tempCelsius.toStringAsFixed(2)} °C';
                          final timeOnly =
                              DateTime.parse(data['list'][i + 1]['dt_txt']);
                          //Extracting icon from 'main'
                          final sky = data['list'][i + 1]['weather'][0]['main'];

                          return HourlyForecastItem(
                            time: DateFormat.j().format(timeOnly),
                            icon: sky == 'Clouds' || sky == 'Rain'
                                ? Icons.cloud
                                : Icons.sunny,
                            temperature:
                                temperatureCelsiusString, // Display temperature in Celsius
                          );
                        }),
                      ),
                    ),

                    //gap between cards
                    const SizedBox(
                      height: 20,
                    ),

                    //additional information heading
                    const Text(
                      'Additional information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),

                    //gap between cards
                    const SizedBox(
                      height: 10,
                    ),

                    //Additional information cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AddtionalInfoItem(
                          icon: Icons.water_drop,
                          label: 'humidity',
                          value: currentHumidity.toString(),
                        ),
                        AddtionalInfoItem(
                          icon: Icons.air,
                          label: 'Wind Speed',
                          value: currentWindspeed.toString(),
                        ),
                        AddtionalInfoItem(
                          icon: Icons.beach_access_rounded,
                          label: 'Pressure',
                          value: currentPressure.toString(),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textEditingController,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Your city name',
                              hintStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              cityName = textEditingController
                                  .text; // Assign to cityName
                              print(cityName);
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 45,
                          ),
                        ),
                      ],
                    )
                  ]),
            ),
          );
        },
      ),
    );
  }
}
