import 'dart:convert';
import 'dart:io';

List<String> OPCOlist = [];
List<List<String>> OPlist = [];
List<List<String>> SYMlist = [];
List<String> SYMCOlist = [];
int inst = 0;
int indx = 0;

void SYMToLt() async {
  var file1 = File('SYMTAB.txt');
  var content = await file1.readAsLines();
  print(content);
  int l = content.length, i;
  for (i = 0; i < l; i++) {
    SYMlist.add(format(content[i]));
  }
  print(SYMlist);
  for (i = 0; i < l; i++) {
    if (SYMCOlist.contains(SYMlist[i][0])) {
      print("Duplicate Label");
      throw FormatException("Duplicate Label");
    }
    SYMCOlist.add(SYMlist[i][0]);
  }
}

void OpToLt() async {
  var file = File('OPTAB.txt');
  if (await file.exists()) {
    var content = await file.readAsLines();
    int l = content.length;
    int i;
    for (i = 0; i < l; i++) {
      OPlist.add(format(content[i]));
      OPCOlist.add(OPlist[i][0]);
    }
  } else {
    throw FileSystemException("File Not Found");
  }
}

String DecToHex(int n) {
  String str = '';
  int k;
  while (n != 0) {
    k = n % 16;
    if (k <= 9) {
      str = k.toString() + str;
    } else {
      k = k - 10 + 65;
      str = str + ascii.decode([k]);
    }
    n = (n / 16).truncate();
  }
  return str;
}

int HexToDec(String str) {
  int n = 0;
  int len = str.length, i;
  str = str.toUpperCase();
  for (i = 0; i < len; i++) {
    if (str[i] == '0') {
      n = n * 16 + 0;
    } else if (str[i] == '1') {
      n = n * 16 + 1;
    } else if (str[i] == '2') {
      n = n * 16 + 2;
    } else if (str[i] == '3') {
      n = n * 16 + 3;
    } else if (str[i] == '4') {
      n = n * 16 + 4;
    } else if (str[i] == '5') {
      n = n * 16 + 5;
    } else if (str[i] == '6') {
      n = n * 16 + 6;
    } else if (str[i] == '7') {
      n = n * 16 + 7;
    } else if (str[i] == '8') {
      n = n * 16 + 8;
    } else if (str[i] == '9') {
      n = n * 16 + 9;
    } else if (str[i] == 'A') {
      n = n * 16 + 10;
    } else if (str[i] == 'B') {
      n = n * 16 + 11;
    } else if (str[i] == 'C') {
      n = n * 16 + 12;
    } else if (str[i] == 'D') {
      n = n * 16 + 13;
    } else if (str[i] == 'E') {
      n = n * 16 + 14;
    } else if (str[i] == 'F') {
      n = n * 16 + 15;
    }
  }
  return n;
}

List<String> format(String str) {
  var len = str.length;
  List<String> list = [];
  String u = '';
  int i = 0;
  for (i = 0; i < len; i++) {
    if (str[i] == ' ') {
      if (u != '') {
        list.add(u);
        u = '';
      }
    } else {
      u = u + str[i];
    }
  }
  if (u != '') {
    list.add(u);
  }
  return list;
}

void pass2() async {
  var file1 = File('Intermediate.txt');
  var file2 = File('output.txt');
  var file3 = File('length.txt');
  String str = '', hex;
  int n, len, i, j, inp, ins, dec;
  List<String> list = [];
  var content = await file1.readAsLines();
  list = format(content[0]);
  if (list[1].toUpperCase() == 'START') {
    i = 1;
    n = list[0].length;
    str = "H^";
    if (n > 6) {
      str = str + list[0].substring(0, 6);
    } else {
      str = str + list[0] + "_" * (6 - n);
    }
    n = list[2].length;
    str = str + "^" + "0" * (6 - n) + list[2];
    hex = await file3.readAsString();
    n = hex.length;
    str = str + "^" + "0" * (6 - n) + hex + '\n';
    n = list[2].length;
    str = str + "T^" + "0" * (6 - n) + list[2];
    hex = DecToHex(inst);
    n = hex.length;
    str = str + "^" + "0" * (2 - n) + hex;
  }
  for (i = 1; i < indx + 1; i++) {
    list = format(content[i]);
    inp = OPCOlist.indexOf(list[2]);
    if (list[3] != "**") {
      ins = SYMCOlist.indexOf(list[3]);
      if (ins == -1) {
        if (list[3].substring(list[3].length - 2, list[3].length) == ",X") {
          ins = SYMCOlist.indexOf(list[3].substring(0, list[3].length - 2));
          hex = SYMlist[ins][1];
          dec = HexToDec(hex);
          dec += 32768;
          hex = DecToHex(dec);
        } else {
          throw FormatException("Label(" + list[3] + ") Not Found");
        }
      } else {
        hex = SYMlist[ins][1];
      }
    } else {
      hex = "0000";
    }
    str = str + "^" + OPlist[inp][1] + hex;
  }
  len = content.length;
  for (i = indx + 1; i < len; i++) {
    list = format(content[i]);
    if (list[2] == "WORD") {
      inp = list[3].length;
      str = str + "\nT^" + list[0] + "^3^" + "0" * (6 - inp) + list[3];
    } else if (list[2] == "BYTE") {
      if (list[3][0] == 'C') {
        hex = list[3].substring(2, list[3].length - 1);
        var chl = ascii.encode(hex);
        inp = chl.length;
        hex = "";
        for (j = 0; j < inp; j++) {
          hex += DecToHex(chl[j]);
        }
        str = str + "\nT^" + list[0] + "^" + DecToHex(inp) + "^" + hex;
      } else if (list[3][0] == 'X') {
        hex = list[3].substring(2, list[3].length - 1);
        inp = (hex.length / 2).round();
        if (inp > (hex.length / 2)) {
          hex = '0' + hex;
        }
        str = str + "\nT^" + list[0] + "^" + DecToHex(inp) + "^" + hex;
      }
    }
  }
  len = content.length;
  list = format(content[0]);
  str = str + "\nE^" + list[2];
  file2.writeAsString(str);
}

void pass1() async {
  OpToLt();
  var file = File('data.txt');
  var file1 = File('SYMTAB.txt');
  var file2 = File('Intermediate.txt');
  var file3 = File('Length.txt');
  String hex, str = '', str1 = '';
  List<String> list = [];
  int i, l, count, count1, m;
  if (await file.exists()) {
    var content = await file.readAsLines();
    var len = content.length;
    list = format(content[0]);
    if (list[1].toUpperCase() == 'START') {
      i = 1;
      count = HexToDec(list[2]);
      str1 = str1 + list[0] + ' ' + list[1] + ' ' + list[2] + '\n';
    } else {
      i = 0;
      count = 0;
    }
    count1 = count;
    for (; i < len; i++) {
      list = format(content[i]);
      l = list.length;
      if (l == 0) continue;
      m = l + 1;
      hex = DecToHex(count);
      list.insert(0, hex);
      if (m < 4) {
        if (OPCOlist.contains(list[1])) {
          list.insert(1, "**");
          m += 1;
        }
        if (m < 4) {
          list.add('**');
        }
      }

      str1 =
          str1 + list[0] + ' ' + list[1] + ' ' + list[2] + ' ' + list[3] + '\n';
      //print(list);
      l = list.length;
      if (l == 4) {
        if (list[1] != "**") {
          str = str + list[1] + ' ' + list[0] + '\n';
        }
        if (OPCOlist.contains(list[2])) {
          count = 3 + count;
          inst = inst + 3;
          indx = indx + 1;
        } else if (list[2] == "RESW") {
          count = 3 * int.parse(list[3]) + count;
        } else if (list[2] == "RESD")
          count = int.parse(list[3]) + count;
        else if (list[2] == "WORD")
          count = 3 + count;
        else if (list[2] == "BYTE") {
          if (list[3][0] == 'C')
            count = count + list[3].length - 3;
          else if (list[3][0] == 'X')
            count = count + (((list[3].length - 3) / 2).round());
        } else if (list[2] == "END")
          ;
        else {
          print("Instruction(" + list[2] + ") Not Found");
          //throw FormatException("Instruction(" + list[2] + ") Not Found");
        }
      }
    }
    file1.writeAsString(str);
    file2.writeAsString(str1);
    count1 = count - count1;
    hex = DecToHex(count1);
    file3.writeAsString(hex);
  } else {
    throw FileSystemException("File Not Found");
  }
  SYMToLt();
  pass2();
}

void main() async {
  pass1();
}
