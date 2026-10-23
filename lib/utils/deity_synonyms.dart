/// Deity names for client-side search. Edit this list; do not add Firestore fields.
///
/// Names in [DeitySynonymGroup.synonyms] are bidirectional with [name].
/// [oneWay] names are found when this group is searched, and searching those
/// names does not return the rest of the group. [parent] is the other one-way
/// link: searching the parent returns this group, and searching this group
/// does not return the parent or the parent's other children.
///
/// Rank the exact group first, then these parent-expansion hits. Ayyappa stays
/// separate from Murugan. Krishna is a child of Vishnu, so a Vishnu search
/// returns Krishna temples and a Krishna search does not return every Vishnu
/// temple.
///
/// Spellings are stored as people type them. Search folds `sh`/`s`, `th`/`t`,
/// `ee`/`i`, `oo`/`u`, `aa`/`a`, `w`/`v`, and doubled consonants before lookup.
class DeitySynonymGroup {
  const DeitySynonymGroup({
    required this.name,
    this.synonyms = const [],
    this.oneWay = const [],
    this.parent,
  });

  final String name;
  final List<String> synonyms;
  final List<String> oneWay;
  final String? parent;
}

/// Validated groups. Add a spelling here rather than on the temple document.
const List<DeitySynonymGroup> deitySynonymGroups = [
  DeitySynonymGroup(
    name: 'Krishna',
    parent: 'Vishnu',
    synonyms: [
      'Krishnan',
      'Kannan',
      'Guruvayurappan',
      'Guruvayoorappan',
      'Krishn',
      'Kanha',
      'Gopal',
      'Gopala',
      // Also a Venkateswara name below. Searching Govinda returns both groups.
      'Govinda',
      'Shrinathji',
      'Udupi Krishna',
    ],
    oneWay: ['Jagannath', 'Vithoba', 'Vitthal'],
  ),
  DeitySynonymGroup(
    name: 'Vishnu',
    synonyms: [
      'Narayana',
      'Narayanan',
      'Perumal',
      'Padmanabha',
      'Padmanabhaswamy',
      'Ranganatha',
      'Ranganathar',
      'Ranganathaswamy',
      'Varadaraja',
      'Narasimha',
      'Lakshmi Narasimha',
    ],
  ),
  DeitySynonymGroup(
    name: 'Venkateswara',
    parent: 'Vishnu',
    synonyms: [
      'Venkateshwara',
      'Venkateswara Swamy',
      'Venkatachalapathy',
      'Srinivasa',
      'Balaji',
      'Tirupati Balaji',
      'Yedukondalavadu',
      'Thimmappa',
      'Govinda',
    ],
  ),
  // No extra Rama spellings were in the validated list.
  DeitySynonymGroup(name: 'Rama', parent: 'Vishnu'),
  DeitySynonymGroup(
    name: 'Shiva',
    synonyms: [
      'Siva',
      'Sivan',
      'Shiv',
      'Shivan',
      'Mahadev',
      'Mahadeva',
      'Mahadevar',
      'Eswara',
      'Eshwara',
      'Ishwar',
      'Iswaran',
      'Easwaran',
      'Shankar',
      'Shankara',
      'Sambhu',
      'Bholenath',
      'Rudra',
      'Mahesh',
      'Linga',
      'Lingeswara',
      'Somnath',
      'Mahakal',
    ],
    oneWay: ['Nataraja'],
  ),
  DeitySynonymGroup(
    name: 'Murugan',
    synonyms: [
      'Subramanya',
      'Subrahmanya',
      'Subramaniam',
      'Subramanian',
      'Kartikeya',
      'Karthikeya',
      'Kartik',
      'Skanda',
      'Kanda',
      'Kandaswamy',
      'Shanmukha',
      'Arumugam',
      'Velan',
      'Senthil',
      'Kumaraswamy',
      'Swaminatha',
      'Dandayudhapani',
      'Palani Andavar',
    ],
  ),
  DeitySynonymGroup(
    name: 'Ayyappa',
    synonyms: [
      'Ayyappan',
      'Ayyappa Swamy',
      'Sastha',
      'Shasta',
      'Dharma Sastha',
      'Manikandan',
      'Hariharaputra',
    ],
    oneWay: ['Ayyanar'],
  ),
  DeitySynonymGroup(
    name: 'Devi',
    synonyms: [
      'Amman',
      'Amma',
      'Ambal',
      'Ambika',
      'Bhagavathi',
      'Bhagavati',
      'Mata',
      'Maa',
      'Shakti',
    ],
  ),
  DeitySynonymGroup(
    name: 'Durga',
    parent: 'Devi',
    synonyms: ['Durgamma', 'Kanaka Durga', 'Chamundi', 'Chamundeshwari'],
    oneWay: ['Vaishno Devi'],
  ),
  DeitySynonymGroup(
    name: 'Parvati',
    parent: 'Devi',
    synonyms: ['Uma', 'Gauri', 'Meenakshi', 'Kamakshi', 'Annapurna'],
  ),
  DeitySynonymGroup(
    name: 'Kali',
    parent: 'Devi',
    synonyms: ['Kaali', 'Kalika', 'Mahakali', 'Bhadrakali', 'Kali Maa'],
  ),
  DeitySynonymGroup(
    name: 'Lakshmi',
    parent: 'Devi',
    synonyms: ['Laxmi', 'Mahalakshmi', 'Mahalaxmi', 'Thayar'],
  ),
  DeitySynonymGroup(
    name: 'Ganesha',
    synonyms: [
      'Ganesh',
      'Ganesan',
      'Vinayaka',
      'Vinayak',
      'Vinayagar',
      'Ganapati',
      'Ganapathi',
      'Ganapathy',
      'Pillaiyar',
      'Pillayar',
      'Vigneshwara',
      'Siddhivinayak',
      'Gajanan',
      'Ganpati',
    ],
  ),
  DeitySynonymGroup(
    name: 'Hanuman',
    synonyms: [
      'Anjaneya',
      'Anjaneyar',
      'Anjaneyulu',
      'Maruti',
      'Bajrangbali',
      'Hanumanji',
    ],
  ),
];
