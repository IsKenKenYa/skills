import testNapi from 'libentry.so';

export default class EntryAbility {
    onCreate(want, launchParam) {
        console.info('EntryAbility onCreate');
        
        testNapi.registerWatcherCrashEvent();
        testNapi.registerWatcherTriggerCrash();
        
        console.info('Crash event watchers registered successfully');
    }

    onDestroy() {
        console.info('EntryAbility onDestroy');
        
        testNapi.removeWatcherCrash();
        testNapi.removeWatcherTrigger();
        testNapi.destroyWatcherCrash();
        testNapi.destroyWatcherTrigger();
        
        console.info('Crash event watchers destroyed successfully');
    }
}