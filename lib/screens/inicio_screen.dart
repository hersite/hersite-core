import 'package:flutter/material.dart';

class InicioPrimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 360,
          height: 640,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: const Color(0xFFF1F8F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 360,
                  height: 640,
                  decoration: ShapeDecoration(
                    color: const Color(0x00D9D9D9),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 16,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: const Color(0xFFB9BAB9),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 344,
                  height: 31,
                  decoration: ShapeDecoration(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 601,
                child: Container(
                  width: 344,
                  height: 31,
                  decoration: ShapeDecoration(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 275,
                top: 609,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: ShapeDecoration(
                    color: Colors.white /* Backgrounds-Primary */,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              Positioned(
                left: 171,
                top: 14,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFB9BAB9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 332,
                top: 16,
                child: Container(
                  width: 16,
                  height: 16,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(),
                ),
              ),
              Positioned(
                left: 302,
                top: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(),
                      child: Stack(),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(),
                      child: Stack(),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                top: 13,
                child: Text(
                  '9:30',
                  style: TextStyle(
                    color: Colors.white /* Backgrounds-Primary */,
                    fontSize: 14,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w400,
                    height: 1.43,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              Positioned(
                left: 45,
                top: 149,
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: ShapeDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/270x270"), //TODO: Cambiar por imagen real
                      fit: BoxFit.cover,
                    ),
                    shape: OvalBorder(side: BorderSide(width: 1)),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: 450,
                child: Container(
                  width: 200,
                  height: 41,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF316533),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 109,
                top: 456,
                child: Text(
                  'INGRESAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontFamily: 'Rowdies',
                    fontWeight: FontWeight.w300,
                    height: 0.93,
                  ),
                ),
              ),
              Positioned(
                left: 80,
                top: 504,
                child: Container(
                  width: 200,
                  height: 41,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 89,
                top: 510,
                child: Text(
                  'REGISTRARSE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontFamily: 'Rowdies',
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                left: 277,
                top: 46,
                child: Container(
                  width: 34,
                  height: 20,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF6EA377),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 311,
                top: 46,
                child: Container(
                  width: 34,
                  height: 20,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE0ECE0),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.50,
                        color: const Color(0xFF6EA377),
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 288,
                top: 47,
                child: SizedBox(
                  width: 18,
                  height: 19,
                  child: Text(
                    'ES',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Poly',
                      fontWeight: FontWeight.w400,
                      height: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 314,
                top: 47,
                child: SizedBox(
                  width: 26,
                  height: 19,
                  child: Text(
                    'QU',
                    style: TextStyle(
                      color: const Color(0xBC98C89A),
                      fontSize: 16,
                      fontFamily: 'Poly',
                      fontWeight: FontWeight.w400,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}