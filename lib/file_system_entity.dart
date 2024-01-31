abstract class FileSystemEntity { // classe mere de Folder et Document
  
  String name;
  bool type; // true = folder, false = file

  FileSystemEntity({
    required this.name,
    required this.type,
  });

}