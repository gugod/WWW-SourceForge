
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Kang-min Liu (gugod@gugod.org)',
    ABSTRACT            => 'Retrieve infromation from SourceForge site',
    NAME                => 'WWW::SourceForge',
    VERSION             => '0.08',
    DISTNAME            => 'WWW-SourceForge',
    PREREQ_PM           => {
        'WWW::Mechanize'   => '0',
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);
