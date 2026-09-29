import 'package:flutter/material.dart';

void main() {
  runApp(const MadNightlifeApp());
}

class Event {
  Event({
    required this.id,
    required this.name,
    required this.venue,
    required this.date,
    required this.description,
    required this.capacity,
    this.registered = 0,
    this.insufficientMatches = false,
  });

  final String id;
  final String name;
  final String venue;
  final DateTime date;
  final String description;
  final int capacity;
  int registered;
  final bool insufficientMatches;

  bool get isFull => registered >= capacity;
}

class UserProfile {
  UserProfile({required this.displayName, required this.goal});

  String displayName;
  String goal;
}

class LocalRepository {
  LocalRepository()
      : events = [
          Event(
            id: 'midnight-mix',
            name: 'Midnight Mix',
            venue: 'Studio 12',
            date: DateTime(2026, 10, 10, 20),
            description:
                'Meet a small group of curious people for an easy-going night of music and conversation.',
            capacity: 12,
            registered: 7,
          ),
          Event(
            id: 'city-lights',
            name: 'City Lights Social',
            venue: 'The Lantern Room',
            date: DateTime(2026, 10, 17, 19, 30),
            description:
                'A guided evening for discovering new corners of the city with people who share your pace.',
            capacity: 16,
            registered: 4,
          ),
          Event(
            id: 'slow-sunday',
            name: 'Slow Sunday',
            venue: 'North Garden',
            date: DateTime(2026, 10, 25, 14),
            description:
                'A relaxed daytime gathering with thoughtful prompts and plenty of room to be yourself.',
            capacity: 8,
            registered: 8,
            insufficientMatches: true,
          ),
        ];

  final List<Event> events;
  UserProfile? profile;
  bool signedIn = false;
  String? registeredEventId;

  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (email.trim().isEmpty || !email.contains('@') || password.length < 6) {
      throw const FormatException('Enter a valid email and a password of 6+ characters.');
    }
    signedIn = true;
  }

  Future<void> createAccount(String email, String password) async {
    await signIn(email, password);
  }

  Future<void> register(Event event) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (event.isFull) {
      throw StateError('This event is full.');
    }
    event.registered++;
    registeredEventId = event.id;
  }

  Event? eventById(String id) {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }
}

class MadNightlifeApp extends StatefulWidget {
  const MadNightlifeApp({super.key});

  @override
  State<MadNightlifeApp> createState() => _MadNightlifeAppState();
}

class _MadNightlifeAppState extends State<MadNightlifeApp> {
  final LocalRepository repository = LocalRepository();
  UserProfile? profile;

  void _signedIn(UserProfile? newProfile) {
    setState(() => profile = newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAD Nightlife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6a3df5)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: profile == null
          ? AuthScreen(repository: repository, onSignedIn: _signedIn)
          : HomeScreen(
              repository: repository,
              profile: profile!,
              onSignOut: () => _signedIn(null),
            ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.repository,
    required this.onSignedIn,
  });

  final LocalRepository repository;
  final ValueChanged<UserProfile> onSignedIn;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool createMode = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (createMode) {
        if (name.text.trim().length < 2) {
          throw const FormatException('Add a display name of at least 2 characters.');
        }
        await widget.repository.createAccount(email.text, password.text);
        widget.repository.profile = UserProfile(
          displayName: name.text.trim(),
          goal: '',
        );
      } else {
        await widget.repository.signIn(email.text, password.text);
        widget.repository.profile =
            UserProfile(displayName: email.text.split('@').first, goal: '');
      }
      if (mounted) widget.onSignedIn(widget.repository.profile!);
    } on Object catch (exception) {
      if (mounted) setState(() => error = exception.toString().replaceFirst('FormatException: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.nightlife, size: 64),
                  const SizedBox(height: 16),
                  Text('MAD Nightlife', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Low-pressure nights, thoughtfully matched.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (createMode)
                    TextField(
                      key: const Key('display-name'),
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Display name'),
                    ),
                  if (createMode) const SizedBox(height: 12),
                  TextField(
                    key: const Key('email'),
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('password'),
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, key: const Key('auth-error'), style: TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: loading
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator())
                        : Text(createMode ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: loading ? null : () => setState(() {
                      createMode = !createMode;
                      error = null;
                    }),
                    child: Text(createMode ? 'Already have an account? Sign in' : 'New here? Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.profile,
    required this.onSignOut,
  });

  final LocalRepository repository;
  final UserProfile profile;
  final VoidCallback onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      BrowseScreen(repository: widget.repository),
      ProfileScreen(profile: widget.profile, onSignOut: widget.onSignOut),
    ];
    return Scaffold(
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key, required this.repository});

  final LocalRepository repository;

  String dateLabel(DateTime date) => '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore events')),
      body: RefreshIndicator(
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 200)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Find your kind of night', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            const Text('Small groups, clear expectations, no pressure.'),
            const SizedBox(height: 20),
            if (repository.events.isEmpty)
              const EmptyState(message: 'No events are available yet. Check back soon.')
            else
              ...repository.events.map(
                (event) => Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${dateLabel(event.date)}\n${event.venue}\n${event.capacity - event.registered} spots left'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailsScreen(repository: repository, event: event),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => CreateEventScreen(repository: repository)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create an event'),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.repository, required this.event});

  final LocalRepository repository;
  final Event event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool loading = false;
  String? error;

  Future<void> register() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.repository.register(widget.event);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AssignmentScreen(event: widget.event),
          ),
        );
      }
    } on Object catch (exception) {
      if (mounted) setState(() => error = exception.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Scaffold(
      appBar: AppBar(title: const Text('Event details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(event.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('${event.venue} · ${event.date.day}/${event.date.month}'),
          const SizedBox(height: 24),
          Text(event.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('${event.capacity - event.registered} places remaining'),
          if (event.insufficientMatches) ...[
            const SizedBox(height: 12),
            const InfoBanner(
              message: 'This event may not have enough compatible matches. You can still register and we will let you know.',
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: event.isFull || loading ? null : register,
            child: loading
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator())
                : Text(event.isFull ? 'Event full' : 'Register for this event'),
          ),
        ],
      ),
    );
  }
}

class AssignmentScreen extends StatelessWidget {
  const AssignmentScreen({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final insufficient = event.insufficientMatches;
    return Scaffold(
      appBar: AppBar(title: const Text('Your night')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(insufficient ? Icons.hourglass_empty : Icons.groups, size: 56),
            const SizedBox(height: 20),
            Text(
              insufficient ? 'We are still finding your group' : 'You are registered',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              insufficient
                  ? 'There are not enough compatible matches yet. We will keep your place and update your assignment when we can.'
                  : 'Your group assignment will be ready closer to ${event.name}. We keep contact details private.',
            ),
            const Spacer(),
            FilledButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('Back to explore')),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.profile, required this.onSignOut});

  final UserProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          const Text('What are you hoping for?'),
          const SizedBox(height: 8),
          GoalPicker(profile: profile),
          const SizedBox(height: 24),
          const InfoBanner(message: 'Your contact details are never shown to other attendees.'),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onSignOut, child: const Text('Sign out')),
        ],
      ),
    );
  }
}

class GoalPicker extends StatefulWidget {
  const GoalPicker({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<GoalPicker> createState() => _GoalPickerState();
}

class _GoalPickerState extends State<GoalPicker> {
  static const goals = ['Meet new people', 'Try something different', 'Find a calm social night'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: widget.profile.goal.isEmpty ? null : widget.profile.goal,
      hint: const Text('Choose a social goal'),
      items: goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
      onChanged: (goal) => setState(() => widget.profile.goal = goal ?? ''),
    );
  }
}

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key, required this.repository});

  final LocalRepository repository;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final name = TextEditingController();
  final venue = TextEditingController();
  final description = TextEditingController();
  final capacity = TextEditingController(text: '12');
  String? error;

  void save() {
    final seats = int.tryParse(capacity.text);
    if (name.text.trim().isEmpty || venue.text.trim().isEmpty || seats == null || seats < 2) {
      setState(() => error = 'Add an event name, venue, and capacity of at least 2.');
      return;
    }
    widget.repository.events.add(
      Event(
        id: 'custom-${widget.repository.events.length}',
        name: name.text.trim(),
        venue: venue.text.trim(),
        date: DateTime(2026, 11, 1, 19),
        description: description.text.trim().isEmpty ? 'A new MAD Nightlife gathering.' : description.text.trim(),
        capacity: seats,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    name.dispose();
    venue.dispose();
    description.dispose();
    capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an event')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Event name')),
          const SizedBox(height: 12),
          TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue')),
          const SizedBox(height: 12),
          TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Short description')),
          const SizedBox(height: 12),
          TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity')),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: save, child: const Text('Publish event')),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message),
      );
}
