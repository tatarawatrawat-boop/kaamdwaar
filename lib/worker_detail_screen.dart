import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';

class WorkerDetailScreen extends StatefulWidget {

  final String name;
  final String work;
  final String area;
  final String phone;
  final double lat;
  final double lng;
  final double rating;
  final String introAudio;

  const WorkerDetailScreen({
    super.key,
    required this.name,
    required this.work,
    required this.area,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.introAudio,
  });

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {

  final AudioPlayer player = AudioPlayer();

  /// CALL
  Future<void> callWorker() async {

    if(widget.phone.isEmpty) return;

    final Uri phoneUri = Uri.parse("tel:${widget.phone}");

    if(await canLaunchUrl(phoneUri)){
      await launchUrl(phoneUri);
    }
  }

  /// NAVIGATE
  Future<void> openMap() async {

    final Uri mapUri = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=${widget.lat},${widget.lng}");

    if(await canLaunchUrl(mapUri)){
      await launchUrl(mapUri);
    }
  }

  /// PLAY INTRO AUDIO
  Future<void> playIntro() async {

    if(widget.introAudio.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No intro audio available")),
      );
      return;
    }

    try{

      await player.setUrl(widget.introAudio);
      player.play();

    }catch(e){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio failed to play")),
      );

    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Worker Profile"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            /// PROFILE CARD
            Card(

              elevation: 5,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Padding(

                padding: const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    /// NAME
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// WORK
                    Text(
                      widget.work,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// AREA
                    Row(
                      children: [
                        const Icon(Icons.location_on,size:18),
                        const SizedBox(width:4),
                        Text(widget.area),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// RATING
                    Row(
                      children: [

                        const Icon(Icons.star,color:Colors.orange),

                        const SizedBox(width:4),

                        Text(
                          widget.rating.toString(),
                          style: const TextStyle(fontSize:16),
                        )

                      ],
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height:16),

            /// MAP CARD
            Card(

              elevation:5,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: ClipRRect(

                borderRadius: BorderRadius.circular(20),

                child: SizedBox(

                  height:220,

                  child: GoogleMap(

                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.lat, widget.lng),
                      zoom: 15,
                    ),

                    markers:{
                      Marker(
                        markerId: const MarkerId("worker"),
                        position: LatLng(widget.lat, widget.lng),
                      )
                    },

                  ),
                ),
              ),
            ),

            const SizedBox(height:20),

            /// INTRO AUDIO
            SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                icon: const Icon(Icons.mic),

                label: const Text("Play Intro Audio"),

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical:14),
                ),

                onPressed: playIntro,
              ),
            ),

            const SizedBox(height:20),

            /// CALL + NAVIGATE
            Row(

              children: [

                Expanded(
                  child: ElevatedButton.icon(

                    icon: const Icon(Icons.call),

                    label: const Text("Call"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical:14),
                    ),

                    onPressed: callWorker,
                  ),
                ),

                const SizedBox(width:12),

                Expanded(
                  child: ElevatedButton.icon(

                    icon: const Icon(Icons.navigation),

                    label: const Text("Navigate"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical:14),
                    ),

                    onPressed: openMap,
                  ),
                ),

              ],
            ),

          ],
        ),
      ),
    );
  }
}