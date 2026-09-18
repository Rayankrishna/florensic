import '../../../enum.dart';
import '../../models/plant_species.dart';

/// Seed catalogue for the Pokedex.
///
/// The production catalogue is served by the species API; this list is the
/// offline stand-in and is the only place species copy lives.
class MockSpecies {
  const MockSpecies._();

  static const SpeciesTag _easy = SpeciesTag('Easy care', SpeciesTagTone.positive);
  static const SpeciesTag _medium =
      SpeciesTag('Moderate care', SpeciesTagTone.warning);
  static const SpeciesTag _tropical = SpeciesTag('Tropical', SpeciesTagTone.neutral);
  static const SpeciesTag _toxic =
      SpeciesTag('Toxic to pets', SpeciesTagTone.warning);
  static const SpeciesTag _petSafe =
      SpeciesTag('Pet friendly', SpeciesTagTone.positive);
  static const SpeciesTag _succulent =
      SpeciesTag('Succulent', SpeciesTagTone.neutral);

  static const List<PlantSpecies> all = [
    PlantSpecies(
      id: 'monstera-deliciosa',
      number: 14,
      commonName: 'Monstera',
      latinName: 'Monstera deliciosa',
      glyph: PlantGlyph.monstera,
      ground: GroundPalette.mint,
      tagline: 'Fast, forgiving, and dramatic once it starts fenestrating.',
      summary:
          'A climbing aroid from the rainforests of southern Mexico and Central '
          'America. Young leaves are solid hearts; as the plant matures and gets '
          'more light, new leaves open with the holes and splits it is known for.',
      difficulty: 'Easy',
      light: 'Bright indirect',
      water: 'Every 7–10 days',
      temperature: '18 – 30°C',
      humidity: '60% and up',
      nativeRange: 'Southern Mexico → Panama',
      matureHeight: '2 – 3 m indoors',
      growthHabit: 'Climbing, needs support',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Yellowing lower leaves',
          body: 'Usually too much water. Let the top 5cm of soil dry before the '
              'next round.',
          tone: MetricStatus.watch,
        ),
        SpeciesIssue(
          title: 'No splits in new leaves',
          body: 'A light problem, not a health one. Move it closer to a bright '
              'window.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: [
        'Wipe the leaves monthly — dust cuts the light they can use.',
        'Give it a moss pole once aerial roots appear; leaves get larger with '
            'support.',
        'Repot every second spring, one pot size up, in a chunky airy mix.',
      ],
    ),
    PlantSpecies(
      id: 'monstera-adansonii',
      number: 27,
      commonName: 'Swiss Cheese Vine',
      latinName: 'Monstera adansonii',
      glyph: PlantGlyph.monsteraAdansonii,
      ground: GroundPalette.sage,
      summary:
          'A trailing cousin of the deliciosa whose leaves are perforated from '
          'the start. Happiest scrambling along a shelf or up a small trellis.',
      difficulty: 'Easy',
      light: 'Bright humid',
      water: 'Every 6–8 days',
      temperature: '18 – 29°C',
      humidity: '65% and up',
      nativeRange: 'Central & South America',
      matureHeight: '2 m trailing',
      growthHabit: 'Vining',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Crisp leaf edges',
          body: 'Air is too dry. Group it with other plants or add a pebble tray.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: [
        'Pinch the growing tips to keep the vine full rather than leggy.',
        'Root cuttings in water — nodes strike within a fortnight.',
      ],
    ),
    PlantSpecies(
      id: 'rhaphidophora-tetrasperma',
      number: 31,
      commonName: 'Mini Monstera',
      latinName: 'Rhaphidophora tetrasperma',
      glyph: PlantGlyph.miniMonstera,
      ground: GroundPalette.mint,
      summary:
          'Not a monstera at all, but it splits like one at a fraction of the '
          'size. A fast climber that rewards a pole within weeks.',
      difficulty: 'Medium',
      light: 'Bright indirect',
      water: 'Every 7 days',
      temperature: '18 – 27°C',
      humidity: '55% and up',
      nativeRange: 'Southern Thailand → Malaysia',
      matureHeight: '1.5 m on a pole',
      growthHabit: 'Climbing',
      tags: [_medium, _tropical, _toxic],
      traits: {PokedexFilter.indoor},
      commonIssues: [
        SpeciesIssue(
          title: 'Leggy growth',
          body: 'Not enough light. Move it nearer a window and give it support.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: [
        'Tie new growth to the pole early — it will not climb on its own.',
        'It drinks more than it looks like it should in summer.',
      ],
    ),
    PlantSpecies(
      id: 'monstera-karstenianum',
      number: 58,
      commonName: 'Monstera Peru',
      latinName: 'Monstera karstenianum',
      glyph: PlantGlyph.pothos,
      ground: GroundPalette.mint,
      summary:
          'Thick, puckered leaves with a lacquered finish. It never fenestrates, '
          'and it is one of the most drought-tolerant plants in the genus.',
      difficulty: 'Easy',
      light: 'Bright indirect',
      water: 'Every 10 days',
      temperature: '18 – 30°C',
      humidity: '50% and up',
      nativeRange: 'Peru',
      matureHeight: '1.5 m climbing',
      growthHabit: 'Climbing',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Soft, translucent leaves',
          body: 'Overwatering. The thick leaves store water — let the pot dry out.',
          tone: MetricStatus.bad,
        ),
      ],
      careTips: ['Treat it like a semi-succulent aroid and underwater rather '
          'than over.'],
    ),
    PlantSpecies(
      id: 'spathiphyllum-wallisii',
      number: 2,
      commonName: 'Peace Lily',
      latinName: 'Spathiphyllum wallisii',
      glyph: PlantGlyph.peaceLily,
      ground: GroundPalette.sage,
      summary:
          'The most communicative houseplant there is — it wilts theatrically '
          'when thirsty and recovers within hours of a drink.',
      difficulty: 'Easy',
      light: 'Low to medium',
      water: 'Every 5–7 days',
      temperature: '18 – 27°C',
      humidity: '50% and up',
      nativeRange: 'Tropical Americas',
      matureHeight: '60 cm',
      growthHabit: 'Clumping',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.lowLight, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Brown leaf tips',
          body: 'Usually tap water minerals. Leave water out overnight first.',
          tone: MetricStatus.watch,
        ),
        SpeciesIssue(
          title: 'No flowers',
          body: 'Too dark. It needs bright indirect light to set a spathe.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: [
        'Let it wilt very slightly before watering — it prefers that to soggy soil.',
        'Deadhead spent spathes at the base to keep it tidy.',
      ],
    ),
    PlantSpecies(
      id: 'dracaena-trifasciata',
      number: 5,
      commonName: 'Snake Plant',
      latinName: 'Dracaena trifasciata',
      glyph: PlantGlyph.snakePlant,
      ground: GroundPalette.mint,
      summary:
          'Near indestructible. Upright, architectural leaves that store water, '
          'so it tolerates being forgotten for weeks at a time.',
      difficulty: 'Easy',
      light: 'Any, tolerates low',
      water: 'Every 14–21 days',
      temperature: '15 – 30°C',
      humidity: '30% and up',
      nativeRange: 'West Africa',
      matureHeight: '1 m',
      growthHabit: 'Upright rosette',
      tags: [_easy, _succulent, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.lowLight, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Mushy base',
          body: 'Root rot from watering too often. Cut back hard and repot dry.',
          tone: MetricStatus.bad,
        ),
      ],
      careTips: [
        'When in doubt, do not water. It is far easier to drown than to starve.',
        'Dust the leaves — they are the whole plant.',
      ],
    ),
    PlantSpecies(
      id: 'ficus-lyrata',
      number: 9,
      commonName: 'Fiddle Leaf Fig',
      latinName: 'Ficus lyrata',
      glyph: PlantGlyph.fiddleLeaf,
      ground: GroundPalette.mint,
      summary:
          'Big, veined, violin-shaped leaves on a woody trunk. It resents change '
          'and will drop leaves after a move, a draught, or a missed watering.',
      difficulty: 'Hard',
      light: 'Bright indirect',
      water: 'Every 7–10 days',
      temperature: '18 – 26°C',
      humidity: '40% and up',
      nativeRange: 'Western Africa',
      matureHeight: '2 – 3 m indoors',
      growthHabit: 'Upright tree',
      tags: [
        SpeciesTag('Demanding', SpeciesTagTone.warning),
        _tropical,
        _toxic,
      ],
      traits: {PokedexFilter.indoor},
      commonIssues: [
        SpeciesIssue(
          title: 'Sudden leaf drop',
          body: 'A change of spot, a cold draught, or a missed watering. Pick one '
              'position and leave it there.',
          tone: MetricStatus.bad,
        ),
        SpeciesIssue(
          title: 'Brown spots at the leaf edge',
          body: 'Underwatering. Water thoroughly until it runs from the base.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: [
        'Rotate a quarter turn each week so it grows evenly.',
        'Keep it a metre back from an unshaded afternoon window.',
        'Feed monthly through spring and summer only.',
      ],
    ),
    PlantSpecies(
      id: 'aloe-barbadensis',
      number: 11,
      commonName: 'Aloe Vera',
      latinName: 'Aloe barbadensis',
      glyph: PlantGlyph.aloe,
      ground: GroundPalette.mint,
      summary:
          'A rosette succulent that wants sun and grit. The thick leaves hold '
          'weeks of water, so the usual mistake is kindness.',
      difficulty: 'Easy',
      light: 'Direct sun',
      water: 'Every 14 days',
      temperature: '13 – 30°C',
      humidity: '30% and up',
      nativeRange: 'Arabian Peninsula',
      matureHeight: '60 cm',
      growthHabit: 'Rosette, offsets freely',
      tags: [_easy, _succulent, _petSafe],
      traits: {PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Flat, splaying leaves',
          body: 'Too little light. Move it to the brightest spot you have.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: [
        'Use a cactus mix — ordinary compost holds far too much water.',
        'Pot up offsets in spring to keep the parent compact.',
      ],
    ),
    PlantSpecies(
      id: 'epipremnum-aureum',
      number: 18,
      commonName: 'Golden Pothos',
      latinName: 'Epipremnum aureum',
      glyph: PlantGlyph.pothos,
      ground: GroundPalette.mint,
      summary:
          'The vine that grows almost anywhere. Marbled gold-and-green hearts on '
          'trailing stems that root wherever they touch soil.',
      difficulty: 'Easy',
      light: 'Low to bright',
      water: 'Every 7–10 days',
      temperature: '15 – 30°C',
      humidity: '40% and up',
      nativeRange: 'French Polynesia',
      matureHeight: '3 m trailing',
      growthHabit: 'Trailing or climbing',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.lowLight, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Variegation fading to plain green',
          body: 'Not enough light. The gold needs brightness to hold.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: [
        'Cut long vines back to the pot and push the cuttings in to thicken it.',
        'It will tell you it is thirsty by drooping, then recover fully.',
      ],
    ),
    PlantSpecies(
      id: 'zamioculcas-zamiifolia',
      number: 22,
      commonName: 'ZZ Plant',
      latinName: 'Zamioculcas zamiifolia',
      glyph: PlantGlyph.zzPlant,
      ground: GroundPalette.sage,
      summary:
          'Glossy, almost artificial-looking leaflets on upright stems, growing '
          'from potato-like rhizomes that carry it through long dry spells.',
      difficulty: 'Easy',
      light: 'Low to medium',
      water: 'Every 18–21 days',
      temperature: '15 – 28°C',
      humidity: '30% and up',
      nativeRange: 'Eastern Africa',
      matureHeight: '90 cm',
      growthHabit: 'Upright, rhizomatous',
      tags: [_easy, _petSafe, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.lowLight, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Yellowing stems at the base',
          body: 'Rhizome rot. Stop watering entirely and check the roots.',
          tone: MetricStatus.bad,
        ),
      ],
      careTips: ['A month between waterings in winter is normal and healthy.'],
    ),
    PlantSpecies(
      id: 'goeppertia-orbifolia',
      number: 34,
      commonName: 'Calathea Orbifolia',
      latinName: 'Goeppertia orbifolia',
      glyph: PlantGlyph.calathea,
      ground: GroundPalette.sage,
      summary:
          'Wide, silver-banded rounds that lift at night and lower by morning. '
          'Beautiful, and unforgiving about water quality and humidity.',
      difficulty: 'Hard',
      light: 'Medium indirect',
      water: 'Every 5–7 days',
      temperature: '18 – 26°C',
      humidity: '65% and up',
      nativeRange: 'Bolivia',
      matureHeight: '80 cm',
      growthHabit: 'Clumping',
      tags: [
        SpeciesTag('Demanding', SpeciesTagTone.warning),
        _tropical,
        _petSafe,
      ],
      traits: {PokedexFilter.indoor, PokedexFilter.petFriendly},
      commonIssues: [
        SpeciesIssue(
          title: 'Crisping edges',
          body: 'Dry air or hard water. Use filtered water and raise humidity.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: [
        'Filtered or rainwater only — it reacts badly to fluoride.',
        'Never let it sit in direct sun; the banding bleaches.',
      ],
    ),
    PlantSpecies(
      id: 'ficus-elastica',
      number: 41,
      commonName: 'Rubber Plant',
      latinName: 'Ficus elastica',
      glyph: PlantGlyph.rubberPlant,
      ground: GroundPalette.mint,
      summary:
          'Broad, lacquered leaves on a sturdy stem. Far more tolerant than its '
          'fiddle-leaf relative and happy to be pruned into shape.',
      difficulty: 'Easy',
      light: 'Bright indirect',
      water: 'Every 10 days',
      temperature: '16 – 28°C',
      humidity: '40% and up',
      nativeRange: 'Southeast Asia',
      matureHeight: '2 m indoors',
      growthHabit: 'Upright tree',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Lower leaves dropping',
          body: 'Normal as it gains height, unless several go at once.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: ['Prune the tip in spring to force branching lower down.'],
    ),
    PlantSpecies(
      id: 'nephrolepis-exaltata',
      number: 47,
      commonName: 'Boston Fern',
      latinName: 'Nephrolepis exaltata',
      glyph: PlantGlyph.fern,
      ground: GroundPalette.sage,
      summary:
          'Arching fronds that want constant moisture and humid air. A bathroom '
          'plant more than a living-room one.',
      difficulty: 'Medium',
      light: 'Medium indirect',
      water: 'Every 3–4 days',
      temperature: '16 – 24°C',
      humidity: '70% and up',
      nativeRange: 'Tropical Americas',
      matureHeight: '70 cm',
      growthHabit: 'Arching clump',
      tags: [_medium, _tropical, _petSafe],
      traits: {PokedexFilter.indoor, PokedexFilter.petFriendly},
      commonIssues: [
        SpeciesIssue(
          title: 'Dropping dry fronds',
          body: 'The air is too dry. It will not recover from a full dry-out.',
          tone: MetricStatus.bad,
        ),
      ],
      careTips: ['Keep the compost damp, never wet, and mist in dry weather.'],
    ),
    PlantSpecies(
      id: 'chlorophytum-comosum',
      number: 52,
      commonName: 'Spider Plant',
      latinName: 'Chlorophytum comosum',
      glyph: PlantGlyph.snakePlant,
      ground: GroundPalette.mint,
      summary:
          'Striped, arching blades that throw out plantlets on long stems. One of '
          'the easiest plants to keep and to give away.',
      difficulty: 'Easy',
      light: 'Bright indirect',
      water: 'Every 7 days',
      temperature: '13 – 27°C',
      humidity: '40% and up',
      nativeRange: 'Southern Africa',
      matureHeight: '45 cm',
      growthHabit: 'Arching, produces runners',
      tags: [_easy, _petSafe],
      traits: {
        PokedexFilter.indoor,
        PokedexFilter.beginner,
        PokedexFilter.petFriendly,
      },
      commonIssues: [
        SpeciesIssue(
          title: 'Brown tips',
          body: 'Tap water. Switch to filtered and trim the tips at an angle.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: ['Pot the plantlets while still attached; they root in days.'],
    ),
    PlantSpecies(
      id: 'pilea-peperomioides',
      number: 63,
      commonName: 'Chinese Money Plant',
      latinName: 'Pilea peperomioides',
      glyph: PlantGlyph.pothos,
      ground: GroundPalette.mint,
      summary:
          'Round, coin-like leaves on slender stalks. It leans hard towards the '
          'light, so turn it often.',
      difficulty: 'Easy',
      light: 'Bright indirect',
      water: 'Every 7–10 days',
      temperature: '15 – 25°C',
      humidity: '40% and up',
      nativeRange: 'Southern China',
      matureHeight: '30 cm',
      growthHabit: 'Upright, offsets freely',
      tags: [_easy, _petSafe],
      traits: {
        PokedexFilter.indoor,
        PokedexFilter.beginner,
        PokedexFilter.petFriendly,
      },
      commonIssues: [
        SpeciesIssue(
          title: 'Leaning to one side',
          body: 'It is following the light. Rotate it a quarter turn weekly.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: ['Separate the pups once they have four or five leaves.'],
    ),
    PlantSpecies(
      id: 'strelitzia-nicolai',
      number: 70,
      commonName: 'Bird of Paradise',
      latinName: 'Strelitzia nicolai',
      glyph: PlantGlyph.fiddleLeaf,
      ground: GroundPalette.sage,
      summary:
          'Paddle leaves on tall stems that split along the veins as they age — '
          'a natural adaptation, not damage.',
      difficulty: 'Medium',
      light: 'Bright, some direct',
      water: 'Every 7–10 days',
      temperature: '18 – 30°C',
      humidity: '50% and up',
      nativeRange: 'South Africa',
      matureHeight: '2 m indoors',
      growthHabit: 'Upright clump',
      tags: [_medium, _tropical, _toxic],
      traits: {PokedexFilter.indoor},
      commonIssues: [
        SpeciesIssue(
          title: 'Split leaves',
          body: 'Normal. Wind and age tear the paddles along the veins.',
          tone: MetricStatus.neutral,
        ),
      ],
      careTips: ['It wants more light than most indoor plants — give it a south '
          'window.'],
    ),
    PlantSpecies(
      id: 'curio-rowleyanus',
      number: 76,
      commonName: 'String of Pearls',
      latinName: 'Curio rowleyanus',
      glyph: PlantGlyph.aloe,
      ground: GroundPalette.mint,
      summary:
          'Trailing strands of spherical leaves. It needs sharp drainage and '
          'considerably more light than most trailing plants.',
      difficulty: 'Medium',
      light: 'Bright, some direct',
      water: 'Every 14 days',
      temperature: '18 – 26°C',
      humidity: '30% and up',
      nativeRange: 'Southwest Africa',
      matureHeight: '60 cm trailing',
      growthHabit: 'Trailing succulent',
      tags: [_medium, _succulent, _toxic],
      traits: {PokedexFilter.indoor},
      commonIssues: [
        SpeciesIssue(
          title: 'Shrivelled pearls',
          body: 'Thirsty — but check for rot first, which looks similar.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: ['Water from below and let the pot drain completely.'],
    ),
    PlantSpecies(
      id: 'chamaedorea-elegans',
      number: 81,
      commonName: 'Parlour Palm',
      latinName: 'Chamaedorea elegans',
      glyph: PlantGlyph.fern,
      ground: GroundPalette.sage,
      summary:
          'A slow, tolerant palm that has been a parlour plant since the '
          'Victorians. Happy in the corner most plants refuse.',
      difficulty: 'Easy',
      light: 'Low to medium',
      water: 'Every 7–10 days',
      temperature: '16 – 26°C',
      humidity: '45% and up',
      nativeRange: 'Southern Mexico → Guatemala',
      matureHeight: '1.2 m',
      growthHabit: 'Clumping palm',
      tags: [_easy, _petSafe],
      traits: {
        PokedexFilter.indoor,
        PokedexFilter.lowLight,
        PokedexFilter.beginner,
        PokedexFilter.petFriendly,
      },
      commonIssues: [
        SpeciesIssue(
          title: 'Spider mites',
          body: 'Dry air invites them. Rinse the fronds and raise humidity.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: ['Never cut the growing tip — a palm stem cannot branch.'],
    ),
    PlantSpecies(
      id: 'philodendron-hederaceum',
      number: 88,
      commonName: 'Philodendron Brasil',
      latinName: 'Philodendron hederaceum',
      glyph: PlantGlyph.pothos,
      ground: GroundPalette.mint,
      summary:
          'Soft green hearts brushed with lime down the centre. Faster and more '
          'forgiving than a pothos in low light.',
      difficulty: 'Easy',
      light: 'Low to bright',
      water: 'Every 7–9 days',
      temperature: '16 – 29°C',
      humidity: '45% and up',
      nativeRange: 'Central America → Caribbean',
      matureHeight: '3 m trailing',
      growthHabit: 'Trailing or climbing',
      tags: [_easy, _tropical, _toxic],
      traits: {PokedexFilter.indoor, PokedexFilter.lowLight, PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Long gaps between leaves',
          body: 'Reaching for light. Move it brighter and prune the bare stems.',
          tone: MetricStatus.watch,
        ),
      ],
      careTips: ['Cut above a node and the vine branches into two.'],
    ),
    PlantSpecies(
      id: 'crassula-ovata',
      number: 95,
      commonName: 'Jade Plant',
      latinName: 'Crassula ovata',
      glyph: PlantGlyph.zzPlant,
      ground: GroundPalette.mint,
      summary:
          'A succulent that slowly builds a woody trunk. With enough sun the leaf '
          'margins blush red.',
      difficulty: 'Easy',
      light: 'Direct sun',
      water: 'Every 14–21 days',
      temperature: '13 – 27°C',
      humidity: '30% and up',
      nativeRange: 'South Africa',
      matureHeight: '1 m',
      growthHabit: 'Woody succulent',
      tags: [_easy, _succulent, _toxic],
      traits: {PokedexFilter.beginner},
      commonIssues: [
        SpeciesIssue(
          title: 'Dropping plump leaves',
          body: 'Overwatering. Let it dry out completely between drinks.',
          tone: MetricStatus.bad,
        ),
      ],
      careTips: ['Water hard, then not at all until the soil is bone dry.'],
    ),
  ];

  static PlantSpecies byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);

  /// Rotating feature on the Pokedex header.
  static PlantSpecies get plantOfTheWeek => all.first;

  static const int catalogueSize = 2412;
}
