import testNapi from 'libentry.so';

export default class EntryAbility {
    onCreate() {
        console.info('EntryAbility onCreate');
        
        testNapi.registerWatcherReceive();
        console.info('onReceive watcher registered');
        
        testNapi.registerWatcherTrigger();
        console.info('onTrigger watcher registered');
    }
    
    onDestroy() {
        console.info('EntryAbility onDestroy');
    }
}