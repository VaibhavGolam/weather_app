import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/widgets/additiona_info_item.dart';
import 'package:weather_app/widgets/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/api.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.cityName});

  final String cityName;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late TextEditingController textEditingController;
  late String cityName;
  late bool isConnected; // Track internet connectivity

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    cityName = widget.cityName;
    isConnected = true; // Assume initially connected
    _checkInternetConnection(); // Check connectivity on init
  }

  Future<void> _checkInternetConnection() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    if (!isConnected) {
      throw 'No internet connection';
    }

    try {
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey'),
      );

      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw 'An unexpected error occurred! Please try refreshing.';
      }

      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weather App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _refreshWeather();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getCurrentWeather(),
        builder: (context, snapshot) {
          if (!isConnected) {
            return Center(
              child: Text(
                'Connect to the internet to view weather data.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentWeatherCard(currentWeatherData),
                const SizedBox(height: 20),
                const Text(
                  'Weather forecast',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
                _buildForecastRow(data),
                const SizedBox(height: 20),
                const Text(
                  'Additional information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 10),
                _buildAdditionalInfoRow(currentWeatherData),
                const SizedBox(height: 20),
                _buildCityInputField(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _refreshWeather() async {
    final enteredCity = textEditingController.text.trim();

    if (enteredCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('City not found. Setting default city to Goa'),
          duration: Duration(seconds: 5),
        ),
      );
      setState(() {
        cityName = 'Goa';
      });
    } else {
      setState(() {
        cityName = enteredCity;
      });
    }

    try {
      await getCurrentWeather();
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('City not found. Setting default city to Goa'),
          duration: Duration(seconds: 5),
        ),
      );
      setState(() {
        cityName = 'Goa';
      });
    }
  }

  Widget _buildCurrentWeatherCard(Map<String, dynamic> currentWeatherData) {
    final tempKelvin = currentWeatherData['main']['temp'] as double;
    final currentTemp = tempKelvin - 273.15;

    final currentSky = currentWeatherData['weather'][0]['main'];

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${currentTemp.toStringAsFixed(2)} °C',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    currentSky == 'Clouds' || currentSky == 'Rain'
                        ? Icons.cloud
                        : Icons.wb_sunny,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentSky,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cityName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForecastRow(Map<String, dynamic> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(5, (i) {
          final tempKelvin = data['list'][i + 1]['main']['temp'] as double;
          final tempCelsius = tempKelvin - 273.15;
          final temperatureCelsiusString =
              '${tempCelsius.toStringAsFixed(2)} °C';
          final timeOnly = DateTime.parse(data['list'][i + 1]['dt_txt']);
          final sky = data['list'][i + 1]['weather'][0]['main'];

          return HourlyForecastItem(
            time: DateFormat.j().format(timeOnly),
            icon:
                sky == 'Clouds' || sky == 'Rain' ? Icons.cloud : Icons.wb_sunny,
            temperature: temperatureCelsiusString,
          );
        }),
      ),
    );
  }

  Widget _buildAdditionalInfoRow(Map<String, dynamic> currentWeatherData) {
    final int currentHumidity = currentWeatherData['main']['humidity'];
    final double currentWindspeed = currentWeatherData['wind']['speed'];
    final int currentPressure = currentWeatherData['main']['pressure'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AddtionalInfoItem(
          icon: Icons.water_drop,
          label: 'Humidity',
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
    );
  }

  Widget _buildCityInputField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: textEditingController,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Your city name',
              hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              cityName = textEditingController.text;
            });
          },
          icon: const Icon(Icons.arrow_forward_rounded, size: 45),
        ),
      ],
    );
  }
}
