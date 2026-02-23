import 'package:flutter/material.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:translator/translator.dart';

class Dank {
  final DateTime? createdAt;
  final String input;
  final String english;
  final String kana;
  final String romaji;

  const Dank({
    required this.english,
    required this.input,
    required this.kana,
    required this.romaji,
    this.createdAt,
  });
}

class KanaHero extends StatefulWidget {
  const KanaHero({super.key});

  @override
  State<KanaHero> createState() => _KanaHeroState();
}

class _KanaHeroState extends State<KanaHero> {
  bool isLoading = false;
  Color actionBlue = Color(0xFF7cacf8);
  Color backgroundBlack = Color(0xFF212121);
  Color backgroundBlacker = Color(0xFF121212);
  Color englishColor = Color(0xFFff9003);
  Color kanaColor = Color(0xFFb87cf8);
  Color romajiColor = Color(0xFF7cf8c6);
  Color textGrey = Color(0xFFa6a6a6);
  Color textWhite = Color(0xFFe8e8e8);
  FocusNode focusInput = FocusNode();
  GoogleTranslator translator = GoogleTranslator();
  KanaKit kanaKit = KanaKit();
  List<Dank> kanabis = [];
  // String translation = '';
  TextEditingController englishCont = TextEditingController();
  TextEditingController inputCont = TextEditingController();
  TextEditingController kanaCont = TextEditingController();
  TextEditingController romajiCont = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: textWhite,
        title: Text('Kana Hero'),
        actions: [
          kanabis.isNotEmpty
              ? IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete, color: textWhite),
                onPressed: () {
                  setState(() {
                    kanabis.clear();
                  });
                },
              )
              : const SizedBox(),
          IconButton(
            tooltip: 'Info',
            icon: Icon(Icons.info, color: textWhite),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    backgroundColor: backgroundBlacker,
                    child: Column(
                      children: [
                        Center(
                          child: Text(
                            'Kana Hero',
                            style: TextStyle(color: textGrey),
                          ),
                        ),
                        const SizedBox(height: 15, width: double.infinity),
                        Wrap(
                          children: [
                            Text(
                              'Translate ',
                              style: TextStyle(color: textGrey),
                            ),
                            Text('input ', style: TextStyle(color: textWhite)),
                            Text('into ', style: TextStyle(color: textGrey)),
                            Text(
                              'English',
                              style: TextStyle(color: englishColor),
                            ),
                            Text(', ', style: TextStyle(color: textGrey)),
                            Text('Kana', style: TextStyle(color: kanaColor)),
                            Text(', and ', style: TextStyle(color: textGrey)),
                            Text(
                              'Romaji',
                              style: TextStyle(color: romajiColor),
                            ),
                            Text('.', style: TextStyle(color: textGrey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Add additional keyboards to your device, e.g. Japanese - Romaji, Japanese - Handwriting, Japanese - Kana.',
                          style: TextStyle(color: textGrey),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'On iOS, go to Settings > General > Keyboard > Keyboards > Add New Keyboard.',
                          style: TextStyle(color: textGrey),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: backgroundBlack,
        elevation: 0,
        height: 45,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Settings',
              icon: Icon(Icons.settings, color: actionBlue, size: 30),
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text('Not working yet.')));
              },
            ),
            const SizedBox(),
            const SizedBox(),
            IconButton(
              tooltip: 'Save',
              icon: Icon(Icons.save, color: actionBlue, size: 30),
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text('Not working yet.')));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Enter Input',
        backgroundColor: actionBlue,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(Icons.text_fields, color: textWhite, size: 30),
          onPressed: () => focusInput.requestFocus(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundBlacker,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: inputCont,
              onChanged: (value) {
                _translate(value);
              },
              onEditingComplete: () {
                _save();
                _closeKeyboard();
                _clear();
              },
              onSubmitted: (_) {},
              focusNode: focusInput,
              decoration: InputDecoration(
                labelText: 'Input',
                labelStyle: TextStyle(color: textGrey),
                filled: true,
                fillColor: backgroundBlack,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textGrey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: textWhite),
            ),
            const SizedBox(height: 8, width: double.infinity),
            // TextField(
            //   controller: englishCont,
            //   readOnly: true,
            //   onChanged: (_) {},
            //   onSubmitted: (_) {},
            //   decoration: InputDecoration(
            //     labelText: 'English Translation',
            //     labelStyle: TextStyle(color: textGrey),
            //     filled: true,
            //     fillColor: backgroundBlack,
            //     enabledBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(8),
            //       borderSide: BorderSide(color: textGrey, width: 1),
            //     ),
            //     focusedBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(8),
            //       borderSide: BorderSide(width: 2),
            //     ),
            //     focusedErrorBorder: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(8),
            //       borderSide: BorderSide(width: 2),
            //     ),
            //   ),
            //   style: Theme.of(
            //     context,
            //   ).textTheme.bodyMedium!.copyWith(color: englishColor),
            // ),
            // const SizedBox(height: 8, width: double.infinity),
            TextField(
              controller: kanaCont,
              readOnly: true,
              onChanged: (_) {},
              onSubmitted: (_) {},
              decoration: InputDecoration(
                labelText: 'Kana Translation',
                labelStyle: TextStyle(color: textGrey),
                filled: true,
                fillColor: backgroundBlack,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textGrey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: kanaColor),
            ),
            const SizedBox(height: 8, width: double.infinity),
            TextField(
              controller: romajiCont,
              readOnly: true,
              onChanged: (_) {},
              onSubmitted: (_) {},
              decoration: InputDecoration(
                labelText: 'Romaji Translation',
                labelStyle: TextStyle(color: textGrey),
                filled: true,
                fillColor: backgroundBlack,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: textGrey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2),
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: Color(0xFF7cf8c6)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: kanabis.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kanabis[index].input,
                          style: TextStyle(color: textWhite),
                        ),
                        isLoading
                            ? LinearProgressIndicator()
                            : Text(
                              kanabis[index].english,
                              style: TextStyle(color: englishColor),
                            ),
                        Text(
                          kanabis[index].kana,
                          style: TextStyle(color: kanaColor),
                        ),
                        Text(
                          kanabis[index].romaji,
                          style: TextStyle(color: romajiColor),
                        ),
                        index != kanabis.length - 1
                            ? Divider(color: textGrey)
                            : const SizedBox(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clear() {
    inputCont.clear();
    kanaCont.clear();
    romajiCont.clear();
  }

  void _closeKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  void _save() {
    if (inputCont.text.isNotEmpty) {
      setState(() {
        kanabis.add(
          Dank(
            createdAt: DateTime.now(),
            english: englishCont.text,
            input: inputCont.text,
            kana: inputCont.text,
            romaji: romajiCont.text,
          ),
        );
        kanabis.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      });
    }
  }

  Future<void> _translate(String input) async {
    setState(() {
      kanaCont.text = kanaKit.toKana(input);
      romajiCont.text = kanaKit.toRomaji(input);
      isLoading = true;
    });

    // await Future.delayed(Duration(seconds: 3));
    var translation = await translator.translate(
      kanaCont.text,
      from: 'auto',
      to: 'en',
    );

    print(translation);
    setState(() {
      englishCont.text = translation.text;
      isLoading = false;
    });
  }
}
