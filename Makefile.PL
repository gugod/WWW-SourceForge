
use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Kang-min Liu (gugod@gugod.org)',
    ABSTRACT            => 'Retrive infromation from SourceForge site',
    NAME                => 'WWW::SourceForge',
    VERSION_FROM        => 'lib/WWW/SourceForge.pm',
    DISTNAME            => 'WWW-SourceForge',
    PREREQ_PM           => {
        'WWW::Mechanize'   => '0',
    },
    dist                => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
    },
);
